import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_smart_hostel_app/screens/login_screen.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String role;
  final String? emailFromLink;
  final String? tokenFromLink;

  const ForgotPasswordScreen({
    super.key,
    required this.role,
    this.emailFromLink,
    this.tokenFromLink,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _saveRole(widget.role);

    if (widget.emailFromLink != null) emailController.text = widget.emailFromLink!;
    if (widget.tokenFromLink != null) {
      otpController.text = widget.tokenFromLink!;
      setState(() {
        _otpSent = true;
        _otpVerified = true;
        _secondsRemaining = 0;
      });
    }
  }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("reset_role", role);
  }

  Future<String> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("reset_role") ?? widget.role;
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().forgotPassword(
        emailController.text.trim(),
        widget.role, // Added role argument
      );

      setState(() => _isLoading = false);

      if (!res['error']) {
        setState(() {
          _otpSent = true;
          _startTimer();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "OTP sent to your email")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().verifyOtp(
        emailController.text.trim(),
        otp,
        widget.role, // Added role argument
      );

      setState(() => _isLoading = false);

      if (!res['error']) {
        setState(() => _otpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "OTP verified")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Invalid OTP")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (newPwController.text.isEmpty ||
        confirmPwController.text.isEmpty ||
        newPwController.text != confirmPwController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().resetPassword(
        emailController.text.trim(),
        otpController.text.trim(),
        newPwController.text.trim(),
        widget.role, // Added role argument
      );

      setState(() => _isLoading = false);

      if (!res['error']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Password reset successful")),
        );

        final savedRole = await _getRole();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(role: savedRole)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Reset failed")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPwController.dispose();
    confirmPwController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/ResetBg.jpeg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.6)),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    final savedRole = await _getRole();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(role: savedRole),
                      ),
                    );
                  },
                ),
                title: const Text("Forgot Password",
                    style: TextStyle(color: Colors.white)),
                centerTitle: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reset Password 🔑 (${widget.role})",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                                hint: "Email", icon: Icons.email),
                          ),
                          const SizedBox(height: 20),
                          if (!_otpSent)
                            _actionButton("Send OTP", _sendOtp, screenHeight),
                          if (_otpSent) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Pinput(
                                    length: 6,
                                    controller: otpController,
                                    onChanged: (_) => setState(() {}),
                                    defaultPinTheme: PinTheme(
                                      width: 50,
                                      height: 60,
                                      textStyle: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white38),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _actionButton(
                                    "Verify",
                                    (!_isLoading &&
                                        otpController.text.length == 6 &&
                                        !_otpVerified)
                                        ? () => _verifyOtp(
                                        otpController.text.trim())
                                        : () {},
                                    screenHeight,
                                    enabled: (!_isLoading &&
                                        otpController.text.length == 6 &&
                                        !_otpVerified),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _secondsRemaining == 0 ? _sendOtp : null,
                                child: Text(
                                  _secondsRemaining == 0
                                      ? "Resend OTP"
                                      : "Resend OTP in $_secondsRemaining s",
                                  style: TextStyle(
                                    color: _secondsRemaining == 0
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (_otpVerified) ...[
                            TextField(
                              controller: newPwController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                  hint: "New Password", icon: Icons.lock),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: confirmPwController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                  hint: "Confirm Password",
                                  icon: Icons.lock_outline),
                            ),
                            const SizedBox(height: 25),
                            _actionButton(
                                "Reset Password", _resetPassword, screenHeight),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, VoidCallback onTap, double screenHeight,
      {bool enabled = true}) {
    return GestureDetector(
      onTap: _isLoading || !enabled ? null : onTap,
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.065,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: enabled
              ? const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFD23F2A)],
          )
              : LinearGradient(
            colors: [Colors.grey, Colors.grey.shade700],
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
