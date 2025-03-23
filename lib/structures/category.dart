import 'dart:convert';

class Category {
  final int id;
  final String name;
  final DateTime updatedAt;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.createdAt,
  });

  String toJson() {
    return json.encode({
      'id': id,
      'name': name,
      'updated_at': updatedAt,
      'created_at': createdAt,
    });
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      updatedAt: json['updated_at'],
      createdAt: json['created_at'],
    );
  }
}
