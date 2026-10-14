import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_node.dart';
import '../models/app_settings.dart';
import 'csv_service.dart';

import '../models/keyword_reply.dart';

class StorageService {
  static const String _keySettings = 'app_settings';
  static const String _keyMenuNodes = 'menu_nodes';
  static const String _keyNativeNodesCache = 'menu_nodes_cache';
  static const String _keyNativeEnabled = 'is_auto_reply_enabled';
  static const String _keyNativeDefaultReply = 'default_reply';
  static const String _keyKeywordReplies = 'keyword_replies';
  static const String _keyNativeKeywordRepliesCache = 'keyword_replies_cache';
  static const String _keyNativeKeywordEnabled = 'is_keyword_reply_enabled';

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
  }

  static Future<List<KeywordReply>> loadKeywordReplies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyKeywordReplies);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        return list.map((item) => KeywordReply.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {}
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
}
