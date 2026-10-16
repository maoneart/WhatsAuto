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
  }) async {
    final systemPrompt = settings.aiCustomPrompt.trim().isNotEmpty
        ? settings.aiCustomPrompt.trim()
        : 'Anda adalah asisten WhatsApp cerdas MaoneAuto. Jawab pertanyaan pengguna dengan ramah, informatif, ringkas, dan jelas dalam bahasa Indonesia.';

    final endpoint = settings.aiProvider == 'gemini'
        ? 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${settings.aiApiKey}'
        : default9RouterUrl;

    try {
      if (settings.aiProvider == 'gemini') {
        final uri = Uri.parse(endpoint);
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
        throw Exception('Gemini API error (Status ${response.statusCode}): ${response.body}');
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
        throw Exception('9Router error (Status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
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
    );

    if (reply.isEmpty) {
      throw Exception('Gagal mendapatkan balasan dari AI Gateway. Pastikan server 9Router aktif di port 20128 atau API key valid.');
    }
    return reply;
  }
}
