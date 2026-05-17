import 'package:flutter/material.dart';
import '../../core/widgets/app_drawer.dart';
import '../../services/supabase_service.dart';
import '../../models/user_profile.dart';

class PublicHomePage extends StatefulWidget {
  const PublicHomePage({super.key});

  @override
  State<PublicHomePage> createState() => _PublicHomePageState();
}

class _PublicHomePageState extends State<PublicHomePage> {
  final _supabaseService = SupabaseService();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      final profile = await _supabaseService.getUserProfile(userId);
      setState(() => _profile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ComplaintEase'),
        actions: [
          StreamBuilder<int>(
            stream: _supabaseService.getUnreadNotificationsCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Badge(
                label: Text(count.toString()),
                isLabelVisible: count > 0,
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${_profile?.name ?? "User"}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A unified platform for all your university complaints.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildRoleQuickActions(context),
            const SizedBox(height: 32),
            _buildInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleQuickActions(BuildContext context) {
    if (_profile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: _getQuickActions(context),
        ),
      ],
    );
  }

  List<Widget> _getQuickActions(BuildContext context) {
    List<Widget> actions = [];

    if (_profile?.role == 'user') {
      actions.add(
        _buildActionCard(
          context,
          'File Complaint',
          Icons.add_circle_outline_rounded,
          Colors.blue,
          () => Navigator.pushNamed(context, '/create-complaint'),
        ),
      );
      actions.add(
        _buildActionCard(
          context,
          'My History',
          Icons.history_rounded,
          Colors.orange,
          () => Navigator.pushNamed(context, '/complaint-history'),
        ),
      );
    } else if (_profile?.role == 'admin') {
      actions.add(
        _buildActionCard(
          context,
          'Admin Panel',
          Icons.dashboard_rounded,
          Colors.deepPurple,
          () => Navigator.pushNamed(context, '/admin-dashboard'),
        ),
      );
      actions.add(
        _buildActionCard(
          context,
          'View Reports',
          Icons.bar_chart_rounded,
          Colors.teal,
          () => Navigator.pushNamed(context, '/reports'),
        ),
      );
    } else if (_profile?.role == 'team') {
      actions.add(
        _buildActionCard(
          context,
          'Tasks',
          Icons.task_alt_rounded,
          Colors.indigo,
          () => Navigator.pushNamed(context, '/team-dashboard'),
        ),
      );
    }

    return actions;
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'University Policy',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'All complaints are reviewed within 24-48 working hours. Please ensure your contact details are up to date in the profile section.',
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }
}
