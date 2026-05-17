import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import '../../models/complaint.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Complaint> _allComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final complaints = await _supabaseService.getComplaints();
      setState(() {
        _allComplaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading report data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reports')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(),
                  const SizedBox(height: 32),
                  _buildChartCard(
                    'Status Distribution',
                    _buildStatusPieChart(),
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    'Categorized Statistics',
                    _buildCategoryBarChart(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimpleStat(
                  'Total',
                  _allComplaints.length.toString(),
                  Colors.blue,
                ),
                _buildSimpleStat(
                  'Pending',
                  _allComplaints
                      .where((c) => c.status == 'Pending')
                      .length
                      .toString(),
                  Colors.orange,
                ),
                _buildSimpleStat(
                  'Resolved',
                  _allComplaints
                      .where((c) => c.status == 'Resolved')
                      .length
                      .toString(),
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            child: chart,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPieChart() {
    final pending = _allComplaints.where((c) => c.status == 'Pending').length;
    final inProgress = _allComplaints
        .where((c) => c.status == 'In Progress')
        .length;
    final resolved = _allComplaints.where((c) => c.status == 'Resolved').length;

    if (_allComplaints.isEmpty) return const Center(child: Text('No data'));

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: pending.toDouble(),
            title: 'Pending',
            color: Colors.orange,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: inProgress.toDouble(),
            title: 'Active',
            color: Colors.blue,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: resolved.toDouble(),
            title: 'Done',
            color: Colors.green,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart() {
    final Map<String, int> counts = {};
    for (var c in _allComplaints) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }

    if (counts.isEmpty) return const Center(child: Text('No data'));

    final sortedKeys = counts.keys.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: counts.values.isEmpty
            ? 10
            : counts.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
        barGroups: sortedKeys.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: counts[entry.value]!.toDouble(),
                color: Theme.of(context).primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      sortedKeys[value.toInt()].substring(0, 3),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
