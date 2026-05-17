import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/complaint.dart';
import 'package:intl/intl.dart';
import '../user/complaint_detail_page.dart';
import '../team/team_complaint_detail_page.dart';

class ActiveDiscussionsPage extends StatefulWidget {
  const ActiveDiscussionsPage({super.key});

  @override
  State<ActiveDiscussionsPage> createState() => _ActiveDiscussionsPageState();
}

class _ActiveDiscussionsPageState extends State<ActiveDiscussionsPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allDiscussions = [];

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getActiveDiscussions();
      setState(() {
        _allDiscussions = data;
      });
    } catch (e) {
      debugPrint('Error loading discussions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDiscussions = _allDiscussions
        .where((d) => d['status'] == 'Pending' || d['status'] == 'In Progress')
        .toList();
    final previousDiscussions = _allDiscussions
        .where((d) => d['status'] == 'Resolved')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Support Chats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDiscussions,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Previous'),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDiscussionList(
                    activeDiscussions,
                    'No active discussions',
                  ),
                  _buildDiscussionList(
                    previousDiscussions,
                    'No previous discussions',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDiscussionList(
    List<Map<String, dynamic>> discussions,
    String emptyMessage,
  ) {
    if (discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscussions,
      child: ListView.builder(
        itemCount: discussions.length,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final disc = discussions[index];
          final complaint = Complaint.fromJson(disc);
          final userName = disc['profiles']?['name'] ?? 'User';
          final commentCount = disc['comments']?[0]?['count'] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(complaint.status),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('By: $userName'),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$commentCount messages',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat(
                          'MMM dd',
                        ).format(complaint.createdAt.toLocal()),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => _navigateToChat(complaint),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToChat(Complaint complaint) {
    final role =
        _supabaseService.client.auth.currentUser?.userMetadata?['role'] ??
        'user';

    if (role == 'admin' || role == 'team') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamComplaintDetailPage(complaint: complaint),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComplaintDetailPage(complaint: complaint),
        ),
      );
    }
  }
}
