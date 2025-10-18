import 'package:flutter/material.dart';
import 'package:new_smart_hostel_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_smart_hostel_app/dashboards/student_dashboard.dart';
import 'package:new_smart_hostel_app/dashboards/agent_dashboard.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final name = prefs.getString('studentName') ?? "Student"; // ✅ consistent key
    final isLoggedOut = prefs.getBool('isLoggedOut') ?? false;
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false; // ✅ new

    if (token != null &&
        token.isNotEmpty &&
        role != null &&
        !isLoggedOut &&
        seenOnboarding) {
      // ✅ User already logged in and onboarding completed
      _navigateToDashboard(role: role, token: token, studentName: name);
    } else {
      // Fully logged out or onboarding not done
      await prefs.clear();
      setState(() => _checkingSession = false);
    }
  }

  void _navigateToDashboard({
    required String role,
    required String token,
    required String studentName,
  }) {
    Widget dashboard;

    if (role.toLowerCase() == "student") {
      dashboard = StudentDashboard(
        initialToken: token,
        role: role,
        studentName: studentName,
      );
    } else {
      dashboard = AgentDashboard(
        initialToken: token,
        role: role,
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  void _continueAs(String role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, Color(0xFF120016)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.1),
              Image.asset(
                'assets/images/brand_logo.png',
                height: size.height * 0.3,
              ),
              const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Column(
                children: [
                  // Continue as Student
                  SizedBox(
                    width: double.infinity,
                    height: size.height * 0.065, // dynamic height
                    child: ElevatedButton(
                      onPressed: () => _continueAs("student"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF93C5FD), // Tailwind blue-300
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Continue as Student",
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.025),
                  // Continue as Agent
                  SizedBox(
                    width: double.infinity,
                    height: size.height * 0.065,
                    child: ElevatedButton(
                      onPressed: () => _continueAs("agent"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDBA74),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Continue as Agent",
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
