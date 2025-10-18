import 'package:flutter/material.dart';
import 'package:new_smart_hostel_app/screens/forgot_password_screen.dart';
import 'package:new_smart_hostel_app/screens/forgot_unique_id_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../animations/fade_slide_transition.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';
import 'package:new_smart_hostel_app/dashboards/student_dashboard.dart';
import 'package:new_smart_hostel_app/dashboards/agent_dashboard.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final String role; // student or agent
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController uniqueIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final name = prefs.getString('studentName') ?? ''; // ✅ consistent key
    final isLoggedOut = prefs.getBool('isLoggedOut') ?? false;
    final logoutTime = prefs.getInt('logoutTime');
    final now = DateTime.now().millisecondsSinceEpoch;
    const thirtyDaysMillis = 30 * 24 * 60 * 60 * 1000;

    bool withinSession = false;
    if (logoutTime != null) {
      withinSession = now - logoutTime <= thirtyDaysMillis;
    }

    // ✅ Check if onboarding already completed
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (token != null &&
        token.isNotEmpty &&
        role != null &&
        !isLoggedOut &&
        withinSession) {
      // ✅ Skip onboarding directly if already seen and logged in
      if (seenOnboarding) {
        if (role == "student") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDashboard(
                studentName: name,
                initialToken: token,
                role: role,
              ),
            ),
          );
        } else if (role == "agent") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AgentDashboard()),
          );
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final data = await ApiService().login(
        emailController.text.trim(),
        passwordController.text.trim(),
        widget.role,
        uniqueId: widget.role.toLowerCase() == 'agent'
            ? uniqueIdController.text.trim()
            : null,
      );

      // Extract token and user/student data from API response
      final token = data['token'] ?? '';
      final userData = data['student'] ?? data['user'] ?? {};
      final name = userData['name'] ?? 'Student';
      final studentId = userData['student_id']; // ✅ store student_id
      final agentId = userData['agent_id']; // optional for agent

      // Save everything consistently
      await prefs.setString('token', token);
      await prefs.setString('role', widget.role);
      await prefs.setString('studentName', name);
      if (studentId != null) await prefs.setInt('student_id', studentId); // ✅
      if (agentId != null) await prefs.setInt('agent_id', agentId); // optional
      await prefs.setBool('isLoggedOut', false);
      await prefs.setInt('logoutTime', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('seenOnboarding', true);

      debugPrint(
          '✅ Login success: $name | Role: ${widget.role} | Token: $token | StudentID: $studentId');

      // Navigate to dashboard
      if (widget.role.toLowerCase() == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              initialToken: token,
              studentName: name,
              role: widget.role,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AgentDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ✅ Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ✅ Dark Overlay
            Container(color: Colors.black.withOpacity(0.45)),

            // ✅ Scrollable content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.03,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      direction: AxisDirection.left,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WelcomeScreen()),
                          );
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // ✅ Login Card
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(size.width * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back 👋",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Login as ${widget.role}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Email
                              TextFormField(
                                controller: emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  hint: "Email",
                                  icon: Icons.email,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  final regex =
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!regex.hasMatch(v)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password
                              TextFormField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  hint: "Password",
                                  icon: Icons.lock,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter your password'
                                    : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(
                                            role: widget.role),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),

                              // Unique ID (Agent only)
                              if (widget.role.toLowerCase() == 'agent') ...[
                                TextFormField(
                                  controller: uniqueIdController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                      hint: "Unique ID", icon: Icons.key),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Enter your Unique ID'
                                      : null,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ForgotUniqueIdScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Forgot Unique ID?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 30),

                              // Login Button
                              GestureDetector(
                                onTap: _isLoading ? null : _handleLogin,
                                child: AnimatedBuilder(
                                  animation: _gradientController,
                                  builder: (context, child) {
                                    return AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 250),
                                      width: double.infinity,
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        gradient: _isLoading
                                            ? null
                                            : const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                            Color(0xFFD23F2A),
                                          ],
                                        ),
                                        color:
                                        _isLoading ? Colors.grey : null,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 25),

                              // Signup
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don’t have an account? ",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (widget.role == "student") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RegisterScreen(role: "student"),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Agents must request Unique ID from Admin"),
                                        ));
                                      }
                                    },
                                    child: const Text(
                                      "Sign up",
                                      style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
