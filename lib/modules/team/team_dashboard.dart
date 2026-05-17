import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

import '../../models/complaint.dart';
import 'team_complaint_detail_page.dart';
import '../../core/widgets/app_drawer.dart';

class TeamDashboard extends StatefulWidget {
  const TeamDashboard({super.key});

  @override
  State<TeamDashboard> createState() => _TeamDashboardState();
}

class _TeamDashboardState extends State<TeamDashboard> {
  final _supabaseService = SupabaseService();
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _refreshComplaints();
  }

  void _refreshComplaints() {
    setState(() {
      _complaintsFuture = _supabaseService.getComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Tasks'),
              Tab(text: 'Resolved History'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: FutureBuilder<List<Complaint>>(
          future: _complaintsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final complaints = snapshot.data ?? [];
            final activeComplaints = complaints
                .where((c) => c.status != 'Resolved')
                .toList();
            final resolvedComplaints = complaints
                .where((c) => c.status == 'Resolved')
                .toList();

            final pendingCount = activeComplaints
                .where((c) => c.status == 'Pending')
                .length;
            final inProgressCount = activeComplaints
                .where((c) => c.status == 'In Progress')
                .length;
            final resolvedTotal = resolvedComplaints.length;

            return TabBarView(
              children: [
                _buildComplaintList(
                  context,
                  activeComplaints,
                  pendingCount: pendingCount,
                  inProgressCount: inProgressCount,
                ),
                _buildComplaintList(
                  context,
                  resolvedComplaints,
                  isHistory: true,
                  resolvedCount: resolvedTotal,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildComplaintList(
    BuildContext context,
    List<Complaint> items, {
    bool isHistory = false,
    int pendingCount = 0,
    int inProgressCount = 0,
    int resolvedCount = 0,
  }) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHistory ? 'Success Summary' : 'Performance Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (!isHistory)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        context,
                        'Pending',
                        pendingCount.toString(),
                        Icons.pending_actions_rounded,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        'In Progress',
                        inProgressCount.toString(),
                        Icons.sync_rounded,
                        Colors.blue,
                      ),
                    ],
                  )
                else
                  _buildStatCard(
                    context,
                    'Total Resolved',
                    resolvedCount.toString(),
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                isHistory
                    ? 'Work History (${items.length})'
                    : 'Assigned Tasks (${items.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                isHistory
                    ? 'No resolved complaints yet.'
                    : 'No active complaints to handle.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final c = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        c.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'By: ${c.userName ?? 'Unknown'} | ${c.category}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSmallStatusBadge(c.status),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TeamComplaintDetailPage(complaint: c),
                          ),
                        );
                        _refreshComplaints();
                      },
                    ),
                  ),
                );
              }, childCount: items.length),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatusBadge(String status) {
    Color color = status == 'Pending'
        ? Colors.orange
        : (status == 'In Progress' ? Colors.blue : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
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
}
