class Complaint {
  final int? id;
  final String userId;
  final String? userName;
  final String category;
  final String title;
  final String description;
  final String? imageUrl;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    this.id,
    required this.userId,
    this.userName,
    required this.category,
    required this.title,
    required this.description,
    this.imageUrl,
    this.status = 'Pending',
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      userId: json['user_id'],
      userName: json['profiles'] != null ? json['profiles']['name'] : null,
      category: json['category'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      status: json['status'],
      adminNote: json['admin_note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'status': status,
      'admin_note': adminNote,
    };
  }
}
