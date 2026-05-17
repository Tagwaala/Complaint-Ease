import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import '../../models/comment.dart';
import 'dart:async';

class TeamComplaintDetailPage extends StatefulWidget {
  final Complaint complaint;

  const TeamComplaintDetailPage({super.key, required this.complaint});

  @override
  State<TeamComplaintDetailPage> createState() =>
      _TeamComplaintDetailPageState();
}

class _TeamComplaintDetailPageState extends State<TeamComplaintDetailPage> {
  final _supabaseService = SupabaseService();
  final _noteController = TextEditingController();
  final _commentController = TextEditingController();
  List<ComplaintComment> _comments = [];
  Timer? _pollingTimer;
  Timer? _presenceTimer;
  bool _isUserOnline = false;
  String _selectedStatus = 'Pending';
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
    _noteController.text = widget.complaint.adminNote ?? '';
    _loadComments();
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
    _supabaseService.updateUserPresence(null);
    _noteController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadComments();
    });
  }

  void _startPresenceHeartbeat() {
    final complaintId = widget.complaint.id;
    if (complaintId != null) {
      _supabaseService.updateUserPresence(complaintId);
      _checkUserOnline();
    }

    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (complaintId != null) {
        _supabaseService.updateUserPresence(complaintId);
        _checkUserOnline();
      }
    });
  }

  Future<void> _checkUserOnline() async {
    final complaintId = widget.complaint.id;
    if (complaintId == null) return;
    try {
      final viewers = await _supabaseService.getOnlineViewers(complaintId);
      if (mounted) {
        setState(() {
          // Check if the specific user who filed the complaint is viewing
          _isUserOnline = viewers.any(
            (v) => v['id'] == widget.complaint.userId,
          );
        });
      }
    } catch (e) {
      debugPrint('Error checking presence: $e');
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

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateComplaintStatus(
        widget.complaint.id!,
        _selectedStatus,
        _noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Update successful!')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Handle Complaint'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _deleteComplaint,
              tooltip: 'Delete Complaint',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.complaint.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'From: ${widget.complaint.userName ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text('Category: ${widget.complaint.category}'),
            Text(
              'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.complaint.createdAt.toLocal())}',
            ),
            if (widget.complaint.imageUrl != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.complaint.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text('Error loading image')),
                ),
              ),
            ],
            const Divider(height: 40),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              widget.complaint.description,
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 40),

            // Discussion Section
            _buildChatSection(),
            const Divider(height: 40),

            const Text(
              'Update Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              items: ['Pending', 'In Progress', 'Resolved'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
            const SizedBox(height: 20),
            const Text(
              'Team Note:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Enter internal notes for this complaint...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updateStatus,
                    child: const Text('Update Complaint'),
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
        _buildSectionHeader('Discussion with User', isOnline: _isUserOnline),
        const SizedBox(height: 20),
        _buildCommentsList(),
        const SizedBox(height: 20),
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
                    hintText: 'Type a message to the user...',
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
              'No messages yet. Send a message to the user!',
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
                isMe ? 'You (Team)' : comment.userName,
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
                  'User Online',
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
