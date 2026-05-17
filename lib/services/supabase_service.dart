import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/comment.dart';
import '../models/feedback.dart';
import '../models/notification.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  // --- Authentication ---

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? department,
  }) async {
    try {
      await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'department': department},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Centralized Error Handler ---

  String _handleError(dynamic e) {
    // 1. Handle Known Safe Auth Exceptions
    if (e is AuthException) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        return 'Invalid email or password.';
      }
      if (e.message.toLowerCase().contains('email not confirmed')) {
        return 'Please confirm your email address.';
      }
      if (e.message.toLowerCase().contains('user already registered')) {
        return 'This email is already in use.';
      }
      // If it's a generic auth message that doesn't contain sensitive links
      if (!e.message.contains('http') && !e.message.contains('supabase')) {
        return e.message;
      }
    }

    // 2. Handle Database Exceptions (Don't leak table names)
    if (e is PostgrestException) {
      return 'Database error occurred. Please try again.';
    }

    // 3. Handle Network / Connectivity Issues (The Security Leak Source)
    final errorStr = e.toString().toLowerCase();

    // Check for common network error signatures
    if (errorStr.contains('socket') ||
        errorStr.contains('clientexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection') ||
        errorStr.contains('network')) {
      return 'Connection failed. Please check your internet and try again.';
    }

    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // 4. Final Safety Guard: Never leak URLs or Hostnames
    if (errorStr.contains('http') || errorStr.contains('supabase.co')) {
      return 'A network error occurred. Please try again later.';
    }

    // Default generic error
    return 'An unexpected error occurred.';
  }

  // --- Profile ---

  Future<UserProfile?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(response);
  }

  Future<void> updateProfile(
    String userId,
    String name,
    String? department,
  ) async {
    await client
        .from('profiles')
        .update({'name': name, 'department': department})
        .eq('id', userId);
  }

  // --- Complaints ---

  Future<List<Complaint>> getComplaints({
    String? userId,
    String? category,
  }) async {
    dynamic query = client
        .from('complaints')
        .select('*, profiles:profiles!complaints_user_id_fkey(name)');

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Complaint.fromJson(e)).toList();
  }

  Future<List<Complaint>> getPublicResolvedComplaints() async {
    final response = await client
        .from('complaints')
        .select('*')
        .eq('status', 'Resolved')
        .limit(3)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Complaint.fromJson(e)).toList();
  }

  Future<List<UserProfile>> getAllProfiles() async {
    final response = await client.from('profiles').select().order('name');
    return (response as List).map((e) => UserProfile.fromJson(e)).toList();
  }

  Future<void> createComplaint(Complaint complaint, dynamic imageSource) async {
    String? imageUrl;

    if (imageSource != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'complaint_images/$fileName';

      if (imageSource is File) {
        await client.storage.from('complaints').upload(path, imageSource);
      } else {
        // Handle web (Uint8List)
        await client.storage.from('complaints').uploadBinary(path, imageSource);
      }
      imageUrl = client.storage.from('complaints').getPublicUrl(path);
    }

    // Insert the complaint (DB Trigger handles notifications now)
    await client
        .from('complaints')
        .insert(complaint.toJson()..['image_url'] = imageUrl);
  }

  Future<void> updateComplaintStatus(
    int complaintId,
    String status,
    String? adminNote,
  ) async {
    // 1. Update the complaint
    await client
        .from('complaints')
        .update({
          'status': status,
          'admin_note': adminNote,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', complaintId);

    // 2. Fetch complaint details to get the user_id (for notification)
    final complaintData = await client
        .from('complaints')
        .select('user_id, title')
        .eq('id', complaintId)
        .single();

    final userId = complaintData['user_id'];
    final complaintTitle = complaintData['title'];

    // 3. Create a notification for the user
    await client.from('notifications').insert({
      'user_id': userId,
      'title': 'Complaint Status Updated',
      'message': 'Your complaint "$complaintTitle" is now $status.',
    });
  }

  // --- Admin Authority ---

  Future<void> updateUserRole(String userId, String newRole) async {
    await client.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  Future<void> deleteUserByAdmin(String userId) async {
    try {
      await client.rpc('delete_user_by_admin', params: {'target_user_id': userId});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteComplaint(int complaintId) async {
    await client.from('complaints').delete().eq('id', complaintId);
  }

  // --- Categories ---

  Future<List<ComplaintCategory>> getCategories() async {
    final response = await client.from('categories').select().order('name');
    return (response as List)
        .map((e) => ComplaintCategory.fromJson(e))
        .toList();
  }

  Future<void> addCategory(String name) async {
    await client.from('categories').insert({'name': name});
  }

  Future<void> deleteCategory(int id) async {
    await client.from('categories').delete().eq('id', id);
  }

  // --- Comments ---

  Future<List<ComplaintComment>> getComments(int complaintId) async {
    final response = await client
        .from('comments')
        .select('*, profiles:profiles!comments_user_id_fkey(name)')
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true);
    return (response as List).map((e) => ComplaintComment.fromJson(e)).toList();
  }

  Stream<List<ComplaintComment>> getCommentsStream(int complaintId) {
    return client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true)
        .map((maps) => maps.map((e) => ComplaintComment.fromJson(e)).toList());
  }

  Future<void> addComment(int complaintId, String content) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final name = user.userMetadata?['name'] ?? 'Unknown';

    // Insert the comment (DB Trigger handles notifications now)
    await client.from('comments').insert({
      'complaint_id': complaintId,
      'user_id': user.id,
      'user_name': name,
      'content': content,
    });
  }

  // --- Feedback ---

  Future<void> submitFeedback(
    int complaintId,
    int rating,
    String review,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client.from('feedback').insert({
      'complaint_id': complaintId,
      'user_id': userId,
      'rating': rating,
      'review': review,
    });
  }

  Future<ComplaintFeedback?> getFeedback(int complaintId) async {
    final response = await client
        .from('feedback')
        .select()
        .eq('complaint_id', complaintId)
        .maybeSingle();
    return response != null ? ComplaintFeedback.fromJson(response) : null;
  }

  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final response = await client
        .from('feedback')
        .select(
          '*, profiles:profiles!feedback_user_id_fkey(name), complaints(title)',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Notifications ---

  Future<List<AppNotification>> getNotifications() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((n) => AppNotification.fromJson(n)).toList();
  }

  Future<void> markNotificationRead(int id) async {
    await client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllNotificationsRead() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  Future<void> clearAllNotifications() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('notifications').delete().eq('user_id', userId);
  }

  Stream<int> getUnreadNotificationsCountStream() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .where((n) => n['user_id'] == userId && n['is_read'] == false)
              .length,
        );
  }

  // --- Presence Methods ---

  Future<void> updateUserPresence(int? complaintId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client
        .from('profiles')
        .update({
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          'viewing_complaint_id': complaintId,
        })
        .eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getOnlineViewers(int complaintId) async {
    final now = DateTime.now().toUtc();
    final threshold = now.subtract(const Duration(seconds: 15));

    final response = await client
        .from('profiles')
        .select('id, name, role')
        .eq('viewing_complaint_id', complaintId)
        .gt('last_seen_at', threshold.toIso8601String());

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getActiveDiscussions() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    // Get user profile to check role
    final profileResponse = await client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    final role = profileResponse['role'];
    final isStaff = role == 'admin' || role == 'team';

    var query = client
        .from('complaints')
        .select(
          '*, profiles:profiles!complaints_user_id_fkey(name), comments(count)',
        );

    if (!isStaff) {
      // Regular users only see their own chats
      query = query.eq('user_id', userId);
    }

    final response = await query.order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, int>> getPublicStats() async {
    try {
      final userCountResponse = await client
          .from('profiles')
          .select('id')
          .count(CountOption.exact);
      
      final resolvedCountResponse = await client
          .from('complaints')
          .select('id')
          .eq('status', 'Resolved')
          .count(CountOption.exact);

      return {
        'totalUsers': userCountResponse.count,
        'resolvedComplaints': resolvedCountResponse.count,
      };
    } catch (e) {
      return {'totalUsers': 0, 'resolvedComplaints': 0};
    }
  }
}
