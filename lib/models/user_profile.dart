class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'user',
      department: json['department'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
