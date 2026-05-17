import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../modules/auth/login_page.dart';
import '../../models/user_profile.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    final userId = supabaseService.client.auth.currentUser?.id;

    return Drawer(
      child: FutureBuilder<UserProfile?>(
        future: userId != null
            ? supabaseService.getUserProfile(userId)
            : Future.value(null),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final role = user?.role;

          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/drawer_header_bg.png'),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.name[0].toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                accountName: Text(
                  user?.name ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(user?.email ?? ''),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline_rounded),
                      title: const Text('Support Chats'),
                      onTap: () =>
                          Navigator.pushNamed(context, '/active-discussions'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('My Profile'),
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),

                    // Admin Section
                    if (role == 'admin') ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                        child: Text(
                          'ADMINISTRATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.people_alt_rounded),
                        title: const Text('Registered Users'),
                        onTap: () => Navigator.pushNamed(context, '/admin-users'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.category_rounded),
                        title: const Text('Manage Categories'),
                        onTap: () =>
                            Navigator.pushNamed(context, '/manage-categories'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.analytics_rounded),
                        title: const Text('Reports & Analysis'),
                        onTap: () => Navigator.pushNamed(context, '/reports'),
                      ),
                    ],

                    // Support Section (For Team/Admin)
                    if (role == 'admin' || role == 'team') ...[
                      if (role != 'admin') const Divider(),
                      ListTile(
                        leading: const Icon(Icons.rate_review_outlined),
                        title: const Text('User Reviews'),
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin-feedback'),
                      ),
                    ],

                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign Out'),
                      onTap: () async {
                        await supabaseService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
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
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
