class AppSettings {
  bool isAutoReplyEnabled;
  String defaultReply;
  String replyTo; // 'all', 'contacts', 'except_contacts', 'except_phone'
  bool enableGroups;
  bool welcomeMessageEnabled;
  String welcomeMessage;
  bool aiReplyEnabled;
  bool aiReplyPersonal;
  bool aiReplyGroup;
  String aiProvider; // '9router', 'gemini', 'openai'
  String aiApiKey;
  String aiCustomPrompt;
  String serverWebhookUrl;
  Map<String, bool> supportedApps;
  bool isKeywordReplyEnabled;
  bool onlyReplyKeywords;
  bool enableReplyHeader;
  String replyHeaderText;
  bool enableReplyFooter;
  String replyFooterText;
  int replyDelaySeconds;
  String replyTimeMode; // 'instantly', 'once', 'delay', 'pause'

  AppSettings({
    this.isAutoReplyEnabled = true,
    this.defaultReply = 'Halo! Saya menggunakan Aplikasi MaoneAuto.',
    this.replyTo = 'all',
    this.enableGroups = false,
    this.welcomeMessageEnabled = false,
    this.welcomeMessage = 'Selamat datang! Ada yang bisa kami bantu?',
    this.aiReplyEnabled = false,
    this.aiReplyPersonal = true,
    this.aiReplyGroup = false,
    this.aiProvider = '9router',
    this.aiApiKey = '',
    this.aiCustomPrompt = 'Anda adalah customer support ramah. Jawab pertanyaan pelanggan dengan singkat dan solutif.',
    this.serverWebhookUrl = '',
    this.isKeywordReplyEnabled = true,
    this.onlyReplyKeywords = false,
    this.enableReplyHeader = false,
    this.replyHeaderText = '*[Balasan Otomatis]*',
    this.enableReplyFooter = false,
    this.replyFooterText = '_Terkirim via MaoneAuto_',
    this.replyDelaySeconds = 0,
    this.replyTimeMode = 'instantly',
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
    'aiReplyPersonal': aiReplyPersonal,
    'aiReplyGroup': aiReplyGroup,
    'aiProvider': aiProvider,
    'aiApiKey': aiApiKey,
    'aiCustomPrompt': aiCustomPrompt,
    'serverWebhookUrl': serverWebhookUrl,
    'isKeywordReplyEnabled': isKeywordReplyEnabled,
    'onlyReplyKeywords': onlyReplyKeywords,
    'enableReplyHeader': enableReplyHeader,
    'replyHeaderText': replyHeaderText,
    'enableReplyFooter': enableReplyFooter,
    'replyFooterText': replyFooterText,
    'replyDelaySeconds': replyDelaySeconds,
    'replyTimeMode': replyTimeMode,
    'supportedApps': supportedApps,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    isAutoReplyEnabled: json['isAutoReplyEnabled'] ?? true,
    defaultReply: json['defaultReply'] ?? 'Halo! Saya menggunakan Aplikasi MaoneAuto.',
    replyTo: json['replyTo'] ?? 'all',
    enableGroups: json['enableGroups'] ?? false,
    welcomeMessageEnabled: json['welcomeMessageEnabled'] ?? false,
    welcomeMessage: json['welcomeMessage'] ?? 'Selamat datang! Ada yang bisa kami bantu?',
    aiReplyEnabled: json['aiReplyEnabled'] ?? false,
    aiReplyPersonal: json['aiReplyPersonal'] ?? true,
    aiReplyGroup: json['aiReplyGroup'] ?? false,
    aiProvider: json['aiProvider'] ?? '9router',
    aiApiKey: json['aiApiKey'] ?? '',
    aiCustomPrompt: json['aiCustomPrompt'] ?? '',
    serverWebhookUrl: json['serverWebhookUrl'] ?? '',
    isKeywordReplyEnabled: json['isKeywordReplyEnabled'] ?? true,
    onlyReplyKeywords: json['onlyReplyKeywords'] ?? false,
    enableReplyHeader: json['enableReplyHeader'] ?? false,
    replyHeaderText: json['replyHeaderText'] ?? '*[Balasan Otomatis]*',
    enableReplyFooter: json['enableReplyFooter'] ?? false,
    replyFooterText: json['replyFooterText'] ?? '_Terkirim via MaoneAuto_',
    replyDelaySeconds: json['replyDelaySeconds'] ?? 0,
    replyTimeMode: json['replyTimeMode'] ?? 'instantly',
    supportedApps: (json['supportedApps'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as bool)) ?? {
      'WhatsApp': true,
      'WhatsApp Business': true,
      'Telegram': false,
      'Messenger': false,
    },
  );
}
