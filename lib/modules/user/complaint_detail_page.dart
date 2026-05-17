import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/complaint.dart';
import '../../services/supabase_service.dart';
import '../../models/comment.dart';
import '../../models/feedback.dart';
import 'dart:async';

class ComplaintDetailPage extends StatefulWidget {
  final Complaint complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final _supabaseService = SupabaseService();
  final _commentController = TextEditingController();
  List<ComplaintComment> _comments = [];
  Timer? _pollingTimer;
  Timer? _presenceTimer;
  bool _isSupportOnline = false;
  ComplaintFeedback? _feedback;
  bool _isLoading = true;
  int _userRating = 0;
  final _feedbackController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPolling();
    _startPresenceHeartbeat();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final user = _supabaseService.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await _supabaseService.getUserProfile(user.id);
        if (mounted) {
          setState(() {
            _isAdmin = profile?.role == 'admin';
          });
        }
      } catch (e) {
        debugPrint('Error checking admin role: $e');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _presenceTimer?.cancel();
    _supabaseService.updateUserPresence(null); // Clear presence on leave
    _commentController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadComments();
    });
  }

  void _startPresenceHeartbeat() {
    // Initial heartbeat
    final complaintId = widget.complaint.id;
    if (complaintId != null) {
      _supabaseService.updateUserPresence(complaintId);
      _checkSupportOnline();
    }

    // Periodic heartbeat
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (complaintId != null) {
        _supabaseService.updateUserPresence(complaintId);
        _checkSupportOnline();
      }
    });
  }

  Future<void> _checkSupportOnline() async {
    final complaintId = widget.complaint.id;
    if (complaintId == null) return;
    try {
      final viewers = await _supabaseService.getOnlineViewers(complaintId);
      if (mounted) {
        setState(() {
          // Check if any admin or team member (other than self) is viewing
          _isSupportOnline = viewers.any(
            (v) =>
                v['role'] != 'user' &&
                v['id'] != _supabaseService.client.auth.currentUser?.id,
          );
        });
      }
    } catch (e) {
      debugPrint('Error checking presence: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadComments();
      final feedback = await _supabaseService.getFeedback(widget.complaint.id!);
      setState(() {
        _feedback = feedback;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _supabaseService.getComments(widget.complaint.id!);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await _supabaseService.addComment(
        widget.complaint.id!,
        _commentController.text.trim(),
      );
      _commentController.clear();
      _loadComments(); // Refresh immediately after sending
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) return;
    try {
      await _supabaseService.submitFeedback(
        widget.complaint.id!,
        _userRating,
        _feedbackController.text.trim(),
      );
      _loadData(); // Refresh feedback
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteComplaint() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _supabaseService.deleteComplaint(widget.complaint.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint deleted successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting complaint: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _deleteComplaint,
              tooltip: 'Delete Complaint',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHeader(context),
                  const SizedBox(height: 25),
                  _buildSection(context, 'Title', widget.complaint.title),
                  _buildSection(context, 'Category', widget.complaint.category),
                  _buildSection(
                    context,
                    'Description',
                    widget.complaint.description,
                  ),
                  _buildSection(
                    context,
                    'Submitted On',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(widget.complaint.createdAt.toLocal()),
                  ),
                  const SizedBox(height: 20),
                  if (widget.complaint.imageUrl != null) ...[
                    const Text(
                      'Attached Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.complaint.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Text('Error loading image')),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                  if (widget.complaint.adminNote != null) ...[
                    _buildAdminNote(),
                    const SizedBox(height: 25),
                  ],

                  // Feedback Section
                  if (widget.complaint.status == 'Resolved') ...[
                    _buildFeedbackSection(),
                    const SizedBox(height: 32),
                  ],

                  // Discussion/Chat Section
                  _buildChatSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Admin Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.complaint.adminNote!,
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    if (_feedback != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Your Feedback',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < _feedback!.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
            ),
            if (_feedback!.review != null && _feedback!.review!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback!.review!,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate the Resolution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'How satisfied are you with the resolution of your complaint?',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _userRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _userRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _userRating > 0 ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Discussion', isOnline: _isSupportOnline),
        const SizedBox(height: 20),
        _buildCommentsList(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onFieldSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(15),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendComment,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    if (_comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet. Start the conversation!',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) => _buildCommentTile(_comments[index]),
    );
  }

  Widget _buildCommentTile(ComplaintComment comment) {
    final isMe = comment.userId == _supabaseService.client.auth.currentUser?.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    comment.userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (!isMe) const SizedBox(width: 8),
              Text(
                isMe ? 'You' : comment.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isMe ? null : Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    comment.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('hh:mm a').format(comment.createdAt.toLocal()),
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    Color color;
    IconData icon;
    switch (widget.complaint.status) {
      case 'Pending':
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case 'In Progress':
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case 'Resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Status'),
              Text(
                widget.complaint.status,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isOnline = false}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (isOnline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Support Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
