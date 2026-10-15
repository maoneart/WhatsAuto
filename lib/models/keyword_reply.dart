class KeywordReply {
  String id;
  String incomingKeywords; // Contoh: "harga, biaya, berapa"
  String replyMessage; // Contoh: "Halo {{nama}}, harga kami mulai dari 100."
  bool isExactMatch; // true: Cocokan Tepat, false: Mengandung
  bool isEnabled; // Aktif / non-aktif
  bool useMenuReply; // Opsi balasan: Menu Balas
  bool useAiReply; // Opsi balasan: ChatGPT / AI
  bool useWebhook; // Opsi balasan: Web Server / Webhook
  bool sendEmailNotification; // Pemberitahuan Balasan: Kirim Email

  KeywordReply({
    required this.id,
    required this.incomingKeywords,
    required this.replyMessage,
    this.isExactMatch = true,
    this.isEnabled = true,
    this.useMenuReply = false,
    this.useAiReply = false,
    this.useWebhook = false,
    this.sendEmailNotification = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'incomingKeywords': incomingKeywords,
        'replyMessage': replyMessage,
        'isExactMatch': isExactMatch,
        'isEnabled': isEnabled,
        'useMenuReply': useMenuReply,
        'useAiReply': useAiReply,
        'useWebhook': useWebhook,
        'sendEmailNotification': sendEmailNotification,
      };

  factory KeywordReply.fromJson(Map<String, dynamic> json) => KeywordReply(
        id: json['id'] ?? '',
        incomingKeywords: json['incomingKeywords'] ?? '',
        replyMessage: json['replyMessage'] ?? '',
        isExactMatch: json['isExactMatch'] ?? true,
        isEnabled: json['isEnabled'] ?? true,
        useMenuReply: json['useMenuReply'] ?? false,
        useAiReply: json['useAiReply'] ?? false,
        useWebhook: json['useWebhook'] ?? json['useGoogleSheets'] ?? false,
        sendEmailNotification: json['sendEmailNotification'] ?? false,
      );
}
