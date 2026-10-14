class AppSettings {
  bool isAutoReplyEnabled;
  String defaultReply;
  String replyTo; // 'all', 'contacts', 'except_contacts', 'except_phone'
  bool enableGroups;
  bool welcomeMessageEnabled;
  String welcomeMessage;
  bool aiReplyEnabled;
  String aiProvider; // '9router', 'gemini', 'openai'
  String aiApiKey;
  String aiCustomPrompt;
  String serverWebhookUrl;
  Map<String, bool> supportedApps;

  AppSettings({
    this.isAutoReplyEnabled = true,
    this.defaultReply = 'Halo! Saya menggunakan Aplikasi MaoneAuto.',
    this.replyTo = 'all',
    this.enableGroups = false,
    this.welcomeMessageEnabled = false,
    this.welcomeMessage = 'Selamat datang! Ada yang bisa kami bantu?',
    this.aiReplyEnabled = false,
    this.aiProvider = '9router',
    this.aiApiKey = '',
    this.aiCustomPrompt = 'Anda adalah customer support ramah. Jawab pertanyaan pelanggan dengan singkat dan solutif.',
    this.serverWebhookUrl = '',
    Map<String, bool>? supportedApps,
  }) : supportedApps = supportedApps ?? {
          'WhatsApp': true,
          'WhatsApp Business': true,
          'Telegram': false,
          'Messenger': false,
        };

  Map<String, dynamic> toJson() => {
    'isAutoReplyEnabled': isAutoReplyEnabled,
    'defaultReply': defaultReply,
    'replyTo': replyTo,
    'enableGroups': enableGroups,
    'welcomeMessageEnabled': welcomeMessageEnabled,
    'welcomeMessage': welcomeMessage,
    'aiReplyEnabled': aiReplyEnabled,
    'aiProvider': aiProvider,
    'aiApiKey': aiApiKey,
    'aiCustomPrompt': aiCustomPrompt,
    'serverWebhookUrl': serverWebhookUrl,
    'supportedApps': supportedApps,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    isAutoReplyEnabled: json['isAutoReplyEnabled'] ?? true,
    defaultReply: json['defaultReply'] ?? 'Halo! Saya menggunakan Aplikasi WhatsAuto.',
    replyTo: json['replyTo'] ?? 'all',
    enableGroups: json['enableGroups'] ?? false,
    welcomeMessageEnabled: json['welcomeMessageEnabled'] ?? false,
    welcomeMessage: json['welcomeMessage'] ?? 'Selamat datang! Ada yang bisa kami bantu?',
    aiReplyEnabled: json['aiReplyEnabled'] ?? false,
    aiProvider: json['aiProvider'] ?? '9router',
    aiApiKey: json['aiApiKey'] ?? '',
    aiCustomPrompt: json['aiCustomPrompt'] ?? '',
    serverWebhookUrl: json['serverWebhookUrl'] ?? '',
    supportedApps: (json['supportedApps'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as bool)) ?? {
      'WhatsApp': true,
      'WhatsApp Business': true,
      'Telegram': false,
      'Messenger': false,
    },
  );
}
