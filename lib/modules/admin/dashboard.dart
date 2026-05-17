import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/complaint.dart';
import 'admin_complaint_detail_page.dart';
import '../../core/widgets/app_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            tooltip: 'Manage Categories',
            onPressed: () => Navigator.pushNamed(context, '/manage-categories'),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'View Users',
            onPressed: () => Navigator.pushNamed(context, '/admin-users'),
          ),
        ],
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

          final pending = complaints.where((e) => e.status == 'Pending').length;
          final inProgress = complaints
              .where((e) => e.status == 'In Progress')
              .length;
          final resolved = complaints
              .where((e) => e.status == 'Resolved')
              .length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatsGrid(pending, inProgress, resolved),
              const SizedBox(height: 30),
              Text(
                'Recent Complaints',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              if (complaints.isEmpty)
                const Center(child: Text('No complaints found.'))
              else
                ...complaints.map((c) => _buildComplaintTile(c)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(int pending, int inProgress, int resolved) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      childAspectRatio: 0.8,
      children: [
        _buildStatCard('Pending', pending.toString(), Colors.orange),
        _buildStatCard('Ongoing', inProgress.toString(), Colors.blue),
        _buildStatCard('Fixed', resolved.toString(), Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintTile(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          complaint.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'By: ${complaint.userName ?? 'Unknown'} | ${complaint.category}',
        ),
        trailing: _buildSmallStatusBadge(complaint.status),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminComplaintDetailPage(complaint: complaint),
            ),
          );
          _refreshComplaints();
        },
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
