import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/okr_screen.dart';
import 'screens/ideas_screen.dart';
import 'screens/market_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      initialRoute: '/',
      routes: {
        '/':           (context) => SplashScreen(),
        '/login':       (context) => LoginScreen(),
        '/signup':      (context) => SignupScreen(),
        '/dashboard':   (context) => DashboardScreen(),
        '/chat':        (context) => ChatScreen(),
        '/analytics':   (context) => AnalyticsScreen(),
        '/tasks':       (context) => TasksScreen(),
        '/okr':         (context) => OKRScreen(),
        '/ideas':       (context) => IdeasScreen(),
        '/market':      (context) => MarketScreen(),
        '/alerts':      (context) => AlertsScreen(),
        '/history':     (context) => HistoryScreen(),
        '/profile':     (context) => ProfileScreen(),
        '/settings':    (context) => SettingsScreen(),
      },
    );
  }
}
