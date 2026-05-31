class Interest {
  final int id;
  final String name;
  final String? category;

  const Interest({required this.id, required this.name, this.category});

  factory Interest.fromJson(Map<String, dynamic> json) => Interest(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Interest && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
