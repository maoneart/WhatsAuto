class SheetReplyItem {
  final String keyword;
  final String reply;
  final int matchOption; // 0: Exact match, 1: Contains match

  SheetReplyItem({
    required this.keyword,
    required this.reply,
    this.matchOption = 1,
  });

  Map<String, dynamic> toJson() => {
    'keyword': keyword,
    'reply': reply,
    'matchOption': matchOption,
  };

  factory SheetReplyItem.fromJson(Map<String, dynamic> json) => SheetReplyItem(
    keyword: json['keyword'] ?? '',
    reply: json['reply'] ?? '',
    matchOption: json['matchOption'] is int ? json['matchOption'] : (int.tryParse('${json['matchOption']}') ?? 1),
  );
}

class SpreadsheetConfig {
  bool isEnabled;
  String sheetUrl;
  String sheetName;
  String lastSyncTime;
  int rowCount;
  List<SheetReplyItem> items;

  SpreadsheetConfig({
    this.isEnabled = false,
    this.sheetUrl = '',
    this.sheetName = '',
    this.lastSyncTime = '',
    this.rowCount = 0,
    List<SheetReplyItem>? items,
  }) : items = items ?? [];

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'sheetUrl': sheetUrl,
    'sheetName': sheetName,
    'lastSyncTime': lastSyncTime,
    'rowCount': rowCount,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory SpreadsheetConfig.fromJson(Map<String, dynamic> json) => SpreadsheetConfig(
    isEnabled: json['isEnabled'] ?? false,
    sheetUrl: json['sheetUrl'] ?? '',
    sheetName: json['sheetName'] ?? '',
    lastSyncTime: json['lastSyncTime'] ?? '',
    rowCount: json['rowCount'] ?? 0,
    items: (json['items'] as List<dynamic>?)
            ?.map((e) => SheetReplyItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
