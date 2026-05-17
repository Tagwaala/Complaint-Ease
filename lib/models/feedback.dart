class ComplaintFeedback {
  final int id;
  final int complaintId;
  final String userId;
  final int rating;
  final String? review;
  final DateTime createdAt;

  ComplaintFeedback({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory ComplaintFeedback.fromJson(Map<String, dynamic> json) {
    return ComplaintFeedback(
      id: json['id'],
      complaintId: json['complaint_id'],
      userId: json['user_id'],
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
