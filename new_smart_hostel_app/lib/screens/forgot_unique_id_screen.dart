import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_smart_hostel_app/screens/login_screen.dart';
import '../services/api_service.dart';

class ForgotUniqueIdScreen extends StatefulWidget {
  const ForgotUniqueIdScreen({super.key});

  @override
  State<ForgotUniqueIdScreen> createState() => _ForgotUniqueIdScreenState();
}

class _ForgotUniqueIdScreenState extends State<ForgotUniqueIdScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newUniqueIdController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
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
      final res = await ApiService().forgotUniqueId(emailController.text.trim());

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "OTP sent to your email")),
      );

      setState(() {
        _otpSent = true;
        _secondsRemaining = 30;
        _startTimer();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _verifyOtpAndResetId() async {
    if (otpController.text.length != 6 || newUniqueIdController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().resetUniqueId(
        emailController.text.trim(),
        otpController.text.trim(),
        newUniqueId: newUniqueIdController.text.trim(),
      );

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Unique ID reset successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(role: 'agent')),
      );
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
    newUniqueIdController.dispose();
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
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text("Forgot Unique ID",
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
                          const Text(
                            "Agent Unique ID Recovery 🔑",
                            style: TextStyle(
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
                                hint: "Agent Email", icon: Icons.email),
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
                                    "Reset ID",
                                    (!_isLoading &&
                                        otpController.text.length == 6 &&
                                        newUniqueIdController.text.isNotEmpty)
                                        ? _verifyOtpAndResetId
                                        : () {},
                                    screenHeight,
                                    enabled: (!_isLoading &&
                                        otpController.text.length == 6 &&
                                        newUniqueIdController.text.isNotEmpty),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: newUniqueIdController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                  hint: "New Unique ID", icon: Icons.key),
                            ),
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
