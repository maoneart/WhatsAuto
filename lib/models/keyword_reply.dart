class KeywordReply {
  String id;
  String incomingKeywords; // Contoh: "harga, biaya, berapa"
  String replyMessage; // Contoh: "Halo {{nama}}, harga kami mulai dari 100."
  bool isExactMatch; // true: Cocokan Tepat, false: Mengandung
  bool isEnabled; // Aktif / non-aktif
  bool useMenuReply; // Opsi balasan: Menu Balas
  bool useAiReply; // Opsi balasan: ChatGPT / AI
  bool useGoogleSheets; // Opsi balasan: Google Sheets
  bool sendEmailNotification; // Pemberitahuan Balasan: Kirim Email

  KeywordReply({
    required this.id,
    required this.incomingKeywords,
    required this.replyMessage,
    this.isExactMatch = true,
    this.isEnabled = true,
    this.useMenuReply = false,
    this.useAiReply = false,
    this.useGoogleSheets = false,
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
        'useGoogleSheets': useGoogleSheets,
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
        useGoogleSheets: json['useGoogleSheets'] ?? false,
        sendEmailNotification: json['sendEmailNotification'] ?? false,
      );
}
