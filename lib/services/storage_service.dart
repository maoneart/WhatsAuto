import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_node.dart';
import '../models/app_settings.dart';
import 'csv_service.dart';

import '../models/keyword_reply.dart';
import '../models/spreadsheet_model.dart';
import '../models/quick_note_model.dart';
import '../models/menu_project.dart';

class StorageService {
  static const String _keySettings = 'app_settings';
  static const String _keyMenuNodes = 'menu_nodes';
  static const String _keyNativeNodesCache = 'menu_nodes_cache';
  static const String _keyMenuProjects = 'menu_projects';
  static const String _keyNativeProjectsCache = 'menu_projects_cache';
  static const String _keyActiveProjectId = 'active_menu_project_id';
  static const String _keyNativeEnabled = 'is_auto_reply_enabled';
  static const String _keyNativeDefaultReply = 'default_reply';
  static const String _keyKeywordReplies = 'keyword_replies';
  static const String _keyNativeKeywordRepliesCache = 'keyword_replies_cache';
  static const String _keyNativeKeywordEnabled = 'is_keyword_reply_enabled';
  static const String _keySpreadsheetConfig = 'spreadsheet_config';
  static const String _keyNativeSpreadsheetCache = 'spreadsheet_items_cache';
  static const String _keyQuickNotes = 'quick_notes';

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySettings);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> map = json.decode(jsonStr);
        return AppSettings.fromJson(map);
      } catch (_) {}
    }
    return AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(settings.toJson());
    await prefs.setString(_keySettings, jsonStr);

    // Sync to native SharedPreferences for background notification service
    await prefs.setBool(_keyNativeEnabled, settings.isAutoReplyEnabled);
    await prefs.setString(_keyNativeDefaultReply, settings.defaultReply);
    await prefs.setBool(_keyNativeKeywordEnabled, settings.isKeywordReplyEnabled);
    await prefs.setBool('only_reply_keywords', settings.onlyReplyKeywords);
    await prefs.setString('reply_to', settings.replyTo);
    await prefs.setBool('enable_groups', settings.enableGroups);
    await prefs.setBool('enable_reply_header', settings.enableReplyHeader);
    await prefs.setString('reply_header_text', settings.replyHeaderText);
    await prefs.setBool('enable_reply_footer', settings.enableReplyFooter);
    await prefs.setString('reply_footer_text', settings.replyFooterText);
    await prefs.setInt('reply_delay_seconds', settings.replyDelaySeconds);
    await prefs.setString('reply_time_mode', settings.replyTimeMode);
    await prefs.setString('supported_apps', json.encode(settings.supportedApps));

    // Sync AI, Welcome & Webhook settings to native SharedPreferences
    await prefs.setBool('welcome_message_enabled', settings.welcomeMessageEnabled);
    await prefs.setString('welcome_message', settings.welcomeMessage);
    await prefs.setBool('ai_reply_enabled', settings.aiReplyEnabled);
    await prefs.setBool('ai_reply_personal', settings.aiReplyPersonal);
    await prefs.setBool('ai_reply_group', settings.aiReplyGroup);
    await prefs.setString('ai_provider', settings.aiProvider);
    await prefs.setString('ai_api_key', settings.aiApiKey);
    await prefs.setString('ai_custom_prompt', settings.aiCustomPrompt);
    await prefs.setString('server_webhook_url', settings.serverWebhookUrl);
  }

  static Future<void> initializeDefaultsIfNeeded() async {
    // 1. Inisialisasi Settings jika belum ada
    final settings = await loadSettings();
    await saveSettings(settings);

    // 2. Inisialisasi Aturan Kata Kunci Bawaan ('hay' & 'menu')
    await loadKeywordReplies();

    // 3. Inisialisasi Pohon Menu Bawaan
    await loadMenuNodes();
  }

  static Future<List<KeywordReply>> loadKeywordReplies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyKeywordReplies);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final rules = list.map((item) => KeywordReply.fromJson(item as Map<String, dynamic>)).toList();
        if (rules.isNotEmpty) {
          return rules;
        }
      } catch (_) {}
    }

    // Default kata kunci bawaan saat awal pasang/install (hay -> hallo, menu -> menu balas)
    final hasInitialized = prefs.getBool('flutter.initialized_default_keywords_v3') ?? false;
    if (!hasInitialized) {
      final defaultRules = [
        KeywordReply(
          id: 'default_hay',
          incomingKeywords: 'hay',
          replyMessage: 'hallo',
          isExactMatch: true,
          isEnabled: true,
          useMenuReply: false,
        ),
        KeywordReply(
          id: 'default_menu',
          incomingKeywords: 'menu',
          replyMessage: 'Silakan pilih menu layanan kami di bawah ini:',
          isExactMatch: true,
          isEnabled: true,
          useMenuReply: true,
        ),
      ];
      await saveKeywordReplies(defaultRules);
      await prefs.setBool('flutter.initialized_default_keywords_v3', true);
      return defaultRules;
    }

    return [];
  }

  static Future<void> saveKeywordReplies(List<KeywordReply> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((k) => k.toJson()).toList();
    final jsonStr = json.encode(jsonList);

    await prefs.setString(_keyKeywordReplies, jsonStr);
    // Sinkronisasi ke cache yang dibaca oleh background notification service
    await prefs.setString(_keyNativeKeywordRepliesCache, jsonStr);
  }

  static Future<List<MenuNode>> loadMenuNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyMenuNodes);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        return list.map((item) => MenuNode.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // Cek apakah ada file CSV di /sdcard/Download/Bug/WhatsAuto_2026_10_14_13.csv
    try {
      const bugCsvPath = '/sdcard/Download/Bug/WhatsAuto_2026_10_14_13.csv';
      final file = File(bugCsvPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final nodes = CsvService.parseWhatsAutoCsv(content);
        if (nodes.isNotEmpty) {
          await saveMenuNodes(nodes);
          return nodes;
        }
      }
    } catch (_) {}

    // Fallback ke sample di assets
    final sampleNodes = await CsvService.loadDefaultSampleCsv();
    if (sampleNodes.isNotEmpty) {
      await saveMenuNodes(sampleNodes);
    }
    return sampleNodes;
  }

  static Future<void> saveMenuNodes(List<MenuNode> nodes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = nodes.map((n) => n.toJson()).toList();
    final jsonStr = json.encode(jsonList);

    await prefs.setString(_keyMenuNodes, jsonStr);
    // Sinkronisasi ke cache yang dibaca oleh native Kotlin service
    await prefs.setString(_keyNativeNodesCache, jsonStr);
  }

  static Future<void> resetToSampleNodes() async {
    const bugCsvPath = '/sdcard/Download/Bug/WhatsAuto_2026_10_14_13.csv';
    final file = File(bugCsvPath);
    if (await file.exists()) {
      final content = await file.readAsString();
      final nodes = CsvService.parseWhatsAutoCsv(content);
      if (nodes.isNotEmpty) {
        await saveMenuNodes(nodes);
        return;
      }
    }
    final sampleNodes = await CsvService.loadDefaultSampleCsv();
    await saveMenuNodes(sampleNodes);
  }

  // =========================================================================
  // Multi-Proyek Menu Balas (Klinik, Makanan, Toko, dll.)
  // =========================================================================
  static Future<List<MenuProject>> loadMenuProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyMenuProjects);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final projects = list.map((item) => MenuProject.fromJson(item as Map<String, dynamic>)).toList();
        if (projects.isNotEmpty) {
          return projects;
        }
      } catch (_) {}
    }

    // Migrasi otomatis atau inisialisasi dari menu_nodes yang sudah ada
    final existingNodes = await loadMenuNodes();
    final defaultProject = MenuProject(
      id: 'default_main',
      name: 'Proyek Utama',
      description: 'Katalog Menu Balas Utama',
      nodes: existingNodes,
    );
    final projects = [defaultProject];
    await saveMenuProjects(projects);
    await setActiveProjectId('default_main');
    return projects;
  }

  static Future<void> saveMenuProjects(List<MenuProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = projects.map((p) => p.toJson()).toList();
    final jsonStr = json.encode(jsonList);

    await prefs.setString(_keyMenuProjects, jsonStr);
    await prefs.setString(_keyNativeProjectsCache, jsonStr);

    // Sinkronkan active project nodes ke menu_nodes_cache untuk kompatibilitas
    final activeId = await getActiveProjectId();
    final activeProject = projects.firstWhere(
      (p) => p.id == activeId,
      orElse: () => projects.first,
    );
    await saveMenuNodes(activeProject.nodes);
  }

  static Future<String> getActiveProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveProjectId) ?? 'default_main';
  }

  static Future<void> setActiveProjectId(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProjectId, projectId);

    // Update menu_nodes_cache dengan nodes dari proyek yang aktif
    final jsonStr = prefs.getString(_keyMenuProjects);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final projects = list.map((item) => MenuProject.fromJson(item as Map<String, dynamic>)).toList();
        final activeProject = projects.firstWhere(
          (p) => p.id == projectId,
          orElse: () => projects.first,
        );
        await saveMenuNodes(activeProject.nodes);
      } catch (_) {}
    }
  }

  static Future<MenuProject> loadActiveProject() async {
    final projects = await loadMenuProjects();
    final activeId = await getActiveProjectId();
    return projects.firstWhere(
      (p) => p.id == activeId,
      orElse: () => projects.first,
    );
  }

  static Future<void> saveActiveProjectNodes(List<MenuNode> nodes) async {
    final projects = await loadMenuProjects();
    final activeId = await getActiveProjectId();
    final index = projects.indexWhere((p) => p.id == activeId);
    if (index != -1) {
      projects[index].nodes = nodes;
      projects[index].updatedAt = DateTime.now();
    } else {
      projects.add(MenuProject(
        id: activeId,
        name: 'Proyek $activeId',
        nodes: nodes,
      ));
    }
    await saveMenuProjects(projects);
  }

  static Future<void> saveProject(MenuProject project) async {
    final projects = await loadMenuProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
    } else {
      projects.add(project);
    }
    await saveMenuProjects(projects);
  }

  static Future<bool> deleteProject(String projectId) async {
    final projects = await loadMenuProjects();
    if (projects.length <= 1) {
      return false; // Minimal harus ada 1 proyek tersisa
    }
    projects.removeWhere((p) => p.id == projectId);
    final activeId = await getActiveProjectId();
    if (activeId == projectId) {
      await setActiveProjectId(projects.first.id);
    }
    await saveMenuProjects(projects);
    return true;
  }

  // =========================================================================
  // Google Spreadsheet Sync
  // =========================================================================
  static Future<SpreadsheetConfig> loadSpreadsheetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySpreadsheetConfig);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> map = json.decode(jsonStr);
        return SpreadsheetConfig.fromJson(map);
      } catch (_) {}
    }
    return SpreadsheetConfig();
  }

  static Future<void> saveSpreadsheetConfig(SpreadsheetConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(config.toJson());
    await prefs.setString(_keySpreadsheetConfig, jsonStr);

    // Sync to native SharedPreferences for background notification service
    await prefs.setBool('is_spreadsheet_reply_enabled', config.isEnabled);
    final itemsList = config.items.map((i) => i.toJson()).toList();
    await prefs.setString(_keyNativeSpreadsheetCache, json.encode(itemsList));
  }

  // =========================================================================
  // Catatan Cepat (Quick Notes)
  // =========================================================================
  static Future<List<QuickNote>> loadQuickNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyQuickNotes);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        return list.map((item) => QuickNote.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    // Return default sample quick notes
    return [
      QuickNote(
        id: '1',
        title: 'Nomor Rekening Pembayaran',
        content: 'BCA: 1234567890 a.n. MaoneArt\nMandiri: 9876543210 a.n. MaoneArt\nKonfirmasi bukti transfer ke nomor ini ya Kak.',
        updatedAt: DateTime.now(),
      ),
      QuickNote(
        id: '2',
        title: 'Alamat Toko & Jam Operasional',
        content: '📍 Alamat Toko: Jl. Karang Satria No. 88, Bekasi.\n🕒 Buka Setiap Hari: 08.00 - 21.00 WIB.',
        updatedAt: DateTime.now(),
      ),
      QuickNote(
        id: '3',
        title: 'Format Pemesanan Cepat',
        content: 'Nama:\nNo. HP:\nAlamat Lengkap:\nPesanan:\nJumlah:',
        updatedAt: DateTime.now(),
      ),
    ];
  }

  static Future<void> saveQuickNotes(List<QuickNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notes.map((n) => n.toJson()).toList();
    await prefs.setString(_keyQuickNotes, json.encode(jsonList));
  }
}
