class ComplaintComment {
  final int id;
  final int complaintId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  ComplaintComment({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    return ComplaintComment(
      id: json['id'],
      complaintId: json['complaint_id'],
      userId: json['user_id'],
      userName: (json['profiles'] != null && json['profiles']['name'] != null)
          ? json['profiles']['name']
          : (json['user_name'] ?? 'Unknown'),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
