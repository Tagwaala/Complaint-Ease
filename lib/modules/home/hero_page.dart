import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/complaint.dart';

class HeroPage extends StatefulWidget {
  const HeroPage({super.key});

  @override
  State<HeroPage> createState() => _HeroPageState();
}

class _HeroPageState extends State<HeroPage> {
  final _supabaseService = SupabaseService();
  late Future<List<Complaint>> _recentResolvedFuture;
  late Future<Map<String, int>> _statsFuture;
  StreamSubscription<AuthState>? _authSubscription;
  String? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _checkCurrentUser();
    
    // Auth Listener: React to login/logout in real-time
    _authSubscription = _supabaseService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final profile = await _supabaseService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userRole = profile?.role;
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingRole = false);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userRole = null;
          _isLoadingRole = false;
        });
      }
    }
  }

  void _refreshData() {
    _recentResolvedFuture = _supabaseService.getPublicResolvedComplaints();
    _statsFuture = _supabaseService.getPublicStats();
  }

  String _getDashboardRoute() {
    switch (_userRole) {
      case 'admin':
        return '/admin-dashboard';
      case 'team':
        return '/team-dashboard';
      default:
        return '/user-home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO HEADER SECTION (Same color as Splash Screen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(width: 12),
                      Text(
                        'ComplaintEase',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Your Voice,\nPrioritized.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transparency, Efficiency & Speed in every community resolution.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // CTA Buttons
                  if (_isLoadingRole)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else if (_userRole != null)
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, _getDashboardRoute()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.2),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dashboard_rounded),
                          const SizedBox(width: 12),
                          Text(
                            'GO TO DASHBOARD',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/signup'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('REGISTER NOW'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('LOGIN'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // LIVE STATS SECTION (Dynamic Data)
            Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<Map<String, int>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final stats =
                      snapshot.data ?? {'totalUsers': 0, 'resolvedComplaints': 0};
                  return Row(
                    children: [
                      _buildStatItem(
                          '${stats['totalUsers']}', 'Users Helped', Icons.people),
                      const SizedBox(width: 16),
                      _buildStatItem('${stats['resolvedComplaints']}',
                          'Issues Solved', Icons.done_all_rounded),
                    ],
                  );
                },
              ),
            ),

            // FEATURES GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Key Features'),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _featureCard('Report Easily', 'Snap & share issues',
                          Icons.camera_alt_outlined),
                      _featureCard('Active Tracking', 'Real-time status',
                          Icons.location_on_outlined),
                      _featureCard('Live Chat', 'Engage with staff',
                          Icons.chat_outlined),
                      _featureCard('Transparent', 'Complete history',
                          Icons.visibility_outlined),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // SUCCESS STORIES (Recent Activity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Recent Success Stories'),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Complaint>>(
                    future: _recentResolvedFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final complaints = snapshot.data ?? [];
                      if (complaints.isEmpty) {
                        return _buildEmptyActivityState();
                      }
                      return Column(
                        children: complaints
                            .take(3)
                            .map((c) => _buildActivityTile(c))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // DEVELOPER CREDITS
            Column(
              children: [
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'Developed by',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Afifa Batool & Laiba Shakoor',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.primaryColor, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.primaryColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(String title, String desc, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primaryColor, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            desc,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Complaint complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'Quick fix in ${complaint.category}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          const Text(
            'RESOLVED',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.grey[400], size: 40),
          const SizedBox(height: 12),
          Text(
            'Waiting for first success stories...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resolved complaints will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
