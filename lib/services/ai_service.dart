import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';

class AiService {
  static const String default9RouterUrl = 'http://127.0.0.1:20128/v1/chat/completions';

  /// Kirim pesan chat ke 9Router AI Gateway atau model AI yang dipilih
  static Future<String> generateReply({
    required String incomingMessage,
    required AppSettings settings,
    String? senderName,
    bool throwOnError = false,
  }) async {
    final systemPrompt = settings.aiCustomPrompt.trim().isNotEmpty
        ? settings.aiCustomPrompt.trim()
        : 'Anda adalah asisten WhatsApp cerdas MaoneAuto. Jawab pertanyaan pengguna dengan ramah, informatif, ringkas, dan jelas dalam bahasa Indonesia.';

    final endpoint = settings.aiProvider == 'gemini'
        ? 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${settings.aiApiKey}'
        : default9RouterUrl;
    final uri = Uri.parse(endpoint);

    try {
      if (settings.aiProvider == 'gemini') {
        if (settings.aiApiKey.trim().isEmpty) {
          throw Exception('Google Gemini API Key belum diisi. Silakan masukkan API Key Anda di menu Balasan AI.');
        }

        final body = json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'System: $systemPrompt\nPesan dari ${senderName ?? 'User'}: $incomingMessage'}
              ]
            }
          ]
        });

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          if (text.toString().trim().isNotEmpty) {
            return text.toString().trim();
          }
        }

        String errDetail = response.body;
        try {
          final errJson = json.decode(utf8.decode(response.bodyBytes));
          if (errJson['error']?['message'] != null) {
            errDetail = errJson['error']['message'];
          }
        } catch (_) {}

        if (response.statusCode == 429) {
          throw Exception('Gemini Kuota / Spending Cap Terlampaui (429): $errDetail');
        } else if (response.statusCode == 400) {
          throw Exception('Gemini API Key Tidak Valid / Salah Format (400): $errDetail');
        } else {
          throw Exception('Gemini API Error (${response.statusCode}): $errDetail');
        }
      } else {
        // 9Router Local Gateway (OpenAI Compatible)
        final token = settings.aiApiKey.isNotEmpty
            ? settings.aiApiKey
            : 'sk-4b367e54ce7fe396-pncx8h-438a2784';
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final body = json.encode({
          'model': 'ag/gemini-3.6-flash-low',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': incomingMessage},
          ],
          'temperature': 0.7,
        });

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final text = data['choices']?[0]?['message']?['content'] ?? '';
          if (text.toString().trim().isNotEmpty) {
            return text.toString().trim();
          }
        }

        String errDetail = response.body;
        try {
          final errJson = json.decode(utf8.decode(response.bodyBytes));
          if (errJson['error']?['message'] != null) {
            errDetail = errJson['error']['message'];
          }
        } catch (_) {}

        throw Exception('9Router Error (${response.statusCode}): $errDetail');
      }
    } catch (e) {
      if (throwOnError) rethrow;
      return '';
    }
  }

  /// Pengujian koneksi AI dari layar pengaturan
  static Future<String> testConnection({
    required String provider,
    required String apiKey,
    required String prompt,
    required String testMessage,
  }) async {
    final settings = AppSettings(
      aiProvider: provider,
      aiApiKey: apiKey,
      aiCustomPrompt: prompt,
    );

    final reply = await generateReply(
      incomingMessage: testMessage.isEmpty ? 'Halo, perkenalkan tokomu!' : testMessage,
      settings: settings,
      senderName: 'Penguji',
      throwOnError: true,
    );

    if (reply.isEmpty) {
      if (provider == 'gemini') {
        throw Exception('Respon dari Google Gemini kosong. Pastikan API Key aktif dan memiliki kuota.');
      } else {
        throw Exception('Gagal mendapatkan balasan dari 9Router. Pastikan server 9Router aktif di port 20128.');
      }
    }
    return reply;
  }
}
