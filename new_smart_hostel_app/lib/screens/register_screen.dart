import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../animations/fade_slide_transition.dart';
import 'login_screen.dart';
import 'package:new_smart_hostel_app/dashboards/student_dashboard.dart';
import 'package:new_smart_hostel_app/dashboards/agent_dashboard.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool _isLoading = false;
  bool _bgLoaded = false;

  late final AnimationController _gradientController;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/bg.jpeg'), context)
        .then((_) => setState(() => _bgLoaded = true));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  /// ---------------- REGISTER LOGIC ----------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await apiService.register(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        role: widget.role,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        final role =
            (await ApiService.getRole())?.toLowerCase() ?? widget.role.toLowerCase();

        final prefs = await SharedPreferences.getInstance();

        if (role == "student") {
          // ✅ Save all required info for persistent login
          final studentName = nameController.text.trim();
          await prefs.setString('studentName', studentName);
          await prefs.setString('name', studentName); // optional fallback
          await prefs.setString('role', role);
          await prefs.setString('token', response['token'] ?? '');
          await prefs.setBool('isLoggedOut', false);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('logoutTime', DateTime.now().millisecondsSinceEpoch);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student registered successfully!")),
          );

          // ✅ Redirect directly to Student Dashboard with name
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDashboard(
                studentName: studentName,
              ),
            ),
          );
        } else if (role == "agent") {
          final isApproved = await ApiService.isApprovedAgent();

          if (isApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Agent registered successfully!")),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AgentDashboard()),
            );
          } else {
            // Pending agent flow
            await prefs.setString('pending_agent_email', emailController.text);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Request submitted! Admin will assign your unique Agent ID soon.",
                ),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LoginScreen(role: widget.role),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Registration failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(role: widget.role)),
        );
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: _bgLoaded ? 1.0 : 0.0,
                child: SizedBox.expand(
                  child: Image.asset('assets/images/bg.jpeg', fit: BoxFit.cover),
                ),
              ),
              Container(color: Colors.black.withOpacity(0.3)),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 200),
                        direction: AxisDirection.left,
                        child: IconButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(role: widget.role),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 400),
                        direction: AxisDirection.right,
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.06),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Create Account ✨",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Sign up to get started",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                _buildInput(
                                  controller: nameController,
                                  hint: "Full Name",
                                  icon: Icons.person,
                                  validator: (v) =>
                                  v!.isEmpty ? "Full name is required" : null,
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                _buildInput(
                                  controller: emailController,
                                  hint: "Email",
                                  icon: Icons.email,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return "Email is required";
                                    final emailRegex =
                                    RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(v))
                                      return "Enter valid email";
                                    return null;
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                _buildInput(
                                  controller: passwordController,
                                  hint: "Password",
                                  icon: Icons.lock,
                                  obscure: obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => setState(
                                            () => obscurePassword = !obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return "Password is required";
                                    if (v.length < 6)
                                      return "At least 6 characters required";
                                    return null;
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                GestureDetector(
                                  onTap: _isLoading ? null : _register,
                                  child: AnimatedBuilder(
                                    animation: _gradientController,
                                    builder: (context, child) {
                                      return AnimatedContainer(
                                        duration:
                                        const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        width: double.infinity,
                                        height: screenHeight * 0.065,
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
                                          "Register",
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
                                SizedBox(height: screenHeight * 0.03),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Already have an account? ",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                LoginScreen(role: widget.role),
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Text(
                                          "Login",
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
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
      ),
      validator: validator,
    );
  }
}
