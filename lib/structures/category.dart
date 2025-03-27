import 'dart:convert';

class Category {
  final String uuid;
  final String name;
  final DateTime updatedAt;
  final DateTime createdAt;

  Category({
    required this.uuid,
    required this.name,
    required this.updatedAt,
    required this.createdAt,
  });

  String toJson() {
    return json.encode({
      'uuid': uuid,
      'name': name,
      'updated_at': updatedAt,
      'created_at': createdAt,
    });
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'],
      name: json['name'],
      updatedAt: json['updated_at'],
      createdAt: json['created_at'],
    );
  }
}
