class Interest {
  final int id;
  final String name;

  const Interest({required this.id, required this.name});

  factory Interest.fromJson(Map<String, dynamic> json) => Interest(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  @override
  bool operator ==(Object other) => other is Interest && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
