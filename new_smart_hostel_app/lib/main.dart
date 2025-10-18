import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_smart_hostel_app/dashboards/student_dashboard.dart';
import 'package:new_smart_hostel_app/dashboards/agent_dashboard.dart';
import 'package:new_smart_hostel_app/screens/welcome_screen.dart';
import 'package:new_smart_hostel_app/screens/login_screen.dart';
import 'package:new_smart_hostel_app/screens/register_screen.dart';
import 'package:new_smart_hostel_app/screens/onboarding_screen.dart';
import 'package:new_smart_hostel_app/screens/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (kDebugMode) {
    // comment this out in production
    // await prefs.remove('seenOnboarding');
  }

  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  final String? role = prefs.getString('role');
  final bool isLoggedOut = prefs.getBool('isLoggedOut') ?? false;
  final int? logoutTime = prefs.getInt('logoutTime');
  final int nowMillis = DateTime.now().millisecondsSinceEpoch;
  final int thirtyDaysMillis = 30 * 24 * 60 * 60 * 1000;

  runApp(SmartHostelApp(
    seenOnboarding: seenOnboarding,
    role: role,
    isLoggedOut: isLoggedOut,
    logoutTime: logoutTime,
    nowMillis: nowMillis,
    thirtyDaysMillis: thirtyDaysMillis,
  ));
}

class SmartHostelApp extends StatefulWidget {
  final bool seenOnboarding;
  final String? role;
  final bool isLoggedOut;
  final int? logoutTime;
  final int nowMillis;
  final int thirtyDaysMillis;

  const SmartHostelApp({
    super.key,
    required this.seenOnboarding,
    required this.role,
    required this.isLoggedOut,
    required this.logoutTime,
    required this.nowMillis,
    required this.thirtyDaysMillis,
  });

  @override
  _SmartHostelAppState createState() => _SmartHostelAppState();
}

class _SmartHostelAppState extends State<SmartHostelApp> {
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _determineStartScreen();
  }

  Future<void> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final hasToken = token != null && token.isNotEmpty;

    Widget screenToShow;

    // ✅ Skip onboarding if already logged in
    if (hasToken) {
      final role = prefs.getString('role');
      final name = prefs.getString('studentName') ?? "Student";

      if (role == "student") {
        screenToShow = StudentDashboard(
          initialToken: token,
          studentName: name,
          role: role!,
        );
      } else if (role == "agent") {
        screenToShow = const AgentDashboard();
      } else {
        screenToShow = const WelcomeScreen();
      }
    } else if (!widget.seenOnboarding) {
      // show onboarding only for first-time users
      screenToShow = const OnboardingScreen();
    } else {
      // not logged in, onboarding already done
      screenToShow = const LoginScreen(role: "student");
    }

    setState(() {
      _initialScreen = screenToShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Hostel App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: _initialScreen,
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/forgot-password')) {
          Uri uri = Uri.parse(settings.name!);
          String? email = uri.queryParameters['email'];
          String? token = uri.queryParameters['token'];

          return MaterialPageRoute(
            builder: (_) => ForgotPasswordScreen(
              role: widget.role ?? "student",
              emailFromLink: email,
              tokenFromLink: token,
            ),
          );
        }

        switch (settings.name) {
          case '/welcome':
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          case '/login':
            final role = settings.arguments as String? ?? "student";
            return MaterialPageRoute(builder: (_) => LoginScreen(role: role));
          case '/register':
            final role = settings.arguments as String? ?? "student";
            return MaterialPageRoute(builder: (_) => RegisterScreen(role: role));
          case '/studentDashboard':
            return MaterialPageRoute(
              builder: (_) => const StudentDashboard(),
            );
          case '/agentDashboard':
            return MaterialPageRoute(
              builder: (_) => const AgentDashboard(),
            );
          default:
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
        }
      },
    );
  }
}
