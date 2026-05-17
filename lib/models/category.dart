class ComplaintCategory {
  final int id;
  final String name;

  ComplaintCategory({required this.id, required this.name});

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) {
    return ComplaintCategory(id: json['id'], name: json['name']);
  }
}
