import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_smart_hostel_app/screens/welcome_screen.dart';

/// 🚀 Full logout: clear everything + sync with backend
Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final role = prefs.getString('role');

  if (token != null && role != null) {
    String apiUrl;

    switch (role.toLowerCase()) {
      case 'student':
        apiUrl = 'http://10.0.2.2:8000/api/student/logout';
        break;
      case 'agent':
        apiUrl = 'http://10.0.2.2:8000/api/agent/logout';
        break;
      case 'admin':
        apiUrl = 'http://10.0.2.2:8000/api/auth/logout';
        break;
      default:
      // fallback to universal logout
        apiUrl = 'http://10.0.2.2:8000/api/logout';
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Backend logout successful");
      } else {
        debugPrint("⚠️ Backend logout failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Logout error: $e");
    }
  }

  // Clear local preferences
  await prefs.setBool('isLoggedOut', true);
  await prefs.setInt('logoutTime', DateTime.now().millisecondsSinceEpoch);
  await prefs.remove('token');
  await prefs.remove('role');
  await prefs.remove('name');

  // Navigate to WelcomeScreen
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
    );
  }
}

