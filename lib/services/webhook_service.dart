import 'dart:convert';
import 'package:http/http.dart' as http;

class WebhookService {
  /// Mengirim payload notifikasi ke Webhook Server dan menerima balasan dinamis
  static Future<String> sendWebhook({
    required String webhookUrl,
    required String sender,
    required String message,
    String? appName,
  }) async {
    final trimmedUrl = webhookUrl.trim();
    if (trimmedUrl.isEmpty) return '';

    try {
      final uri = Uri.parse(trimmedUrl);
      final body = json.encode({
        'sender': sender,
        'message': message,
        'app': appName ?? 'WhatsApp',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bodyStr = utf8.decode(response.bodyBytes).trim();
        if (bodyStr.isEmpty) return '';

        try {
          final jsonMap = json.decode(bodyStr);
          if (jsonMap is Map && jsonMap.containsKey('reply')) {
            return jsonMap['reply'].toString().trim();
          }
        } catch (_) {
          // Response berupa plain text biasa
          return bodyStr;
        }
      }
    } catch (_) {}
    return '';
  }

  /// Tes koneksi webhook
  static Future<String> testWebhook(String webhookUrl) async {
    final reply = await sendWebhook(
      webhookUrl: webhookUrl,
      sender: 'Test User',
      message: 'Ping Webhook Server Test',
      appName: 'MaoneAuto Tester',
    );
    if (reply.isEmpty) {
      throw Exception('Tidak ada respon atau server mengembalikan respon kosong.');
    }
    return reply;
  }
}
