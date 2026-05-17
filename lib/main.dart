import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "core/constants.dart";
import "core/theme.dart";
import "modules/auth/splash_screen.dart";
import "modules/auth/login_page.dart";
import "modules/auth/signup_page.dart";
import "modules/user/home_page.dart";
import "modules/user/create_complaint_page.dart";
import "modules/user/complaint_history_page.dart";
import "modules/admin/dashboard.dart";
import "modules/admin/user_list_page.dart";
import "modules/team/team_dashboard.dart";
import "modules/home/public_home_page.dart";
import "modules/home/notification_list_page.dart";
import "modules/profile/profile_page.dart";
import "modules/home/active_discussions_page.dart";
import "modules/admin/reports_page.dart";
import "modules/auth/forgot_password_page.dart";
import "modules/admin/manage_categories_page.dart";
import "modules/admin/feedback_list_page.dart";
import "modules/home/hero_page.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  runApp(const ComplaintEaseApp());
}

class ComplaintEaseApp extends StatelessWidget {
  const ComplaintEaseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ComplaintEase",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignupPage(),
        "/user-home": (context) => const UserHomePage(),
        "/create-complaint": (context) => const CreateComplaintPage(),
        "/complaint-history": (context) => const ComplaintHistoryPage(),
        "/admin-dashboard": (context) => const AdminDashboard(),
        "/admin-users": (context) => const AdminUserListPage(),
        "/team-dashboard": (context) => const TeamDashboard(),
        "/public-home": (context) => const PublicHomePage(),
        "/profile": (context) => const ProfilePage(),
        "/reports": (context) => const ReportsPage(),
        "/notifications": (context) => const NotificationListPage(),
        "/forgot-password": (context) => const ForgotPasswordPage(),
        "/manage-categories": (context) => const CategoryManagementPage(),
        "/admin-feedback": (context) => const FeedbackListPage(),
        "/active-discussions": (context) => const ActiveDiscussionsPage(),
        "/hero": (context) => const HeroPage(),
      },
    );
  }
}
