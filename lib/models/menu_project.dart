import 'menu_node.dart';

class MenuProject {
  final String id;
  String name;
  String description;
  List<MenuNode> nodes;
  DateTime createdAt;
  DateTime updatedAt;

  MenuProject({
    required this.id,
    required this.name,
    this.description = '',
    required this.nodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MenuProject.fromJson(Map<String, dynamic> json) => MenuProject(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Menu Proyek',
        description: json['description']?.toString() ?? '',
        nodes: (json['nodes'] as List<dynamic>?)
                ?.map((n) => MenuNode.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  MenuProject copyWith({
    String? id,
    String? name,
    String? description,
    List<MenuNode>? nodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      nodes: nodes ?? this.nodes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
