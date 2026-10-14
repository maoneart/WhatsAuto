class MenuNode {
  final String id;
  String text;
  String parentId;
  int type; // 1: Prompt/Header/Response Message, 2: Option / Sub-menu Item

  MenuNode({
    required this.id,
    required this.text,
    required this.parentId,
    required this.type,
  });

  bool get isPrompt => type == 1;
  bool get isOption => type == 2;
  bool get isRoot => parentId.toLowerCase() == 'parent';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'parentId': parentId,
    'type': type,
  };

  factory MenuNode.fromJson(Map<String, dynamic> json) => MenuNode(
    id: json['id']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    parentId: json['parentId']?.toString() ?? 'parent',
    type: int.tryParse(json['type']?.toString() ?? '2') ?? 2,
  );

  List<dynamic> toCsvRow() => [
    id,
    text,
    parentId,
    type,
  ];

  MenuNode copyWith({
    String? id,
    String? text,
    String? parentId,
    int? type,
  }) {
    return MenuNode(
      id: id ?? this.id,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
    );
  }
}
