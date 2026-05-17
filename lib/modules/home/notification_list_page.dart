import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/notification.dart';
import 'package:intl/intl.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final _supabaseService = SupabaseService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _supabaseService.getNotifications();
      setState(() => _notifications = notifications);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _supabaseService.markNotificationRead(id);
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _supabaseService.markAllNotificationsRead();
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.clearAllNotifications();
        _loadNotifications();
      } catch (e) {
        debugPrint('Error clearing notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all),
              onPressed: _markAllRead,
            ),
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  color: notification.isRead ? null : Colors.blue[50],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? Colors.grey[200]
                          : Colors.blue,
                      child: Icon(
                        notification.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: notification.isRead ? Colors.grey : Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd MMM, hh:mm a',
                          ).format(notification.createdAt.toLocal()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!notification.isRead) {
                        _markRead(notification.id);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
