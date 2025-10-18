import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

enum UserRole { student, agent, generic }

class AuthService {
  /// ---------------- LOGIN ----------------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final bool useGenericAuth = role == UserRole.generic;
    final endpoint = useGenericAuth ? 'auth/login' : '${role.name}/login';
    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    final response = await http.post(
      url,
      headers: {"Accept": "application/json"},
      body: {'email': email, 'password': password},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      if (data.containsKey("token")) await prefs.setString("token", data["token"]);
      if (data.containsKey("user")) {
        final user = data["user"];
        await prefs.setString("name", user["name"] ?? "");
        await prefs.setString("email", user["email"] ?? "");
        await prefs.setString("role", user["role"].toString().toLowerCase());

        // ✅ Save student_id for students
        if (role == UserRole.student) {
          final studentId = user["student_id"] ?? user["id"];
          if (studentId != null) await prefs.setInt("student_id", studentId);
        }

        // ✅ Save agent approval & special ID
        if (role == UserRole.agent) {
          bool approved = user["is_approved"] ?? false;
          await prefs.setBool("is_approved", approved);
          await prefs.setString("special_id", user["special_id"] ?? "");

          // ❌ Block login if agent is not approved
          if (!approved) {
            throw Exception(
                "Your account is not approved yet by the admin. Please wait for approval.");
          }
        }
      }
    }

    return data;
  }

  /// ---------------- REGISTER ----------------
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final bool useGenericAuth = role == UserRole.generic;
    final endpoint = useGenericAuth ? 'auth/register' : '${role.name}/register';
    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    final response = await http.post(
      url,
      headers: {"Accept": "application/json"},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role.name,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      if (data.containsKey("token")) await prefs.setString("token", data["token"]);
      if (data.containsKey("user")) {
        final user = data["user"];
        await prefs.setString("name", user["name"] ?? "");
        await prefs.setString("email", user["email"] ?? "");
        await prefs.setString("role", user["role"].toString().toLowerCase());

        // ✅ Store student_id for students
        if (role == UserRole.student) {
          final studentId = user["student_id"] ?? user["id"];
          if (studentId != null) await prefs.setInt("student_id", studentId);
        }

        // ✅ Store agent approval & special ID
        if (role == UserRole.agent) {
          await prefs.setBool("is_approved", user["is_approved"] ?? false);
          await prefs.setString("special_id", user["special_id"] ?? "");
        }
      }
    }

    return data;
  }

  /// ---------------- LOGOUT ----------------
  static Future<void> logout({required UserRole role}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    final endpoint = role == UserRole.generic ? 'auth/logout' : '${role.name}/logout';
    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    await prefs.clear();
  }

  /// ---------------- CURRENT USER ----------------
  static Future<Map<String, dynamic>> getCurrentUser({required UserRole role}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    final endpoint = role == UserRole.generic ? 'auth/me' : '${role.name}/details';
    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  /// ---------------- PASSWORD RESET ----------------
  static Future<Map<String, dynamic>> sendOtp(String email, UserRole role) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/${role.name}/password/forgot");

    final response = await http.post(
      url,
      headers: {"Accept": "application/json"},
      body: {'email': email},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/${role.name}/password/reset");

    final response = await http.post(
      url,
      headers: {"Accept": "application/json"},
      body: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );

    return jsonDecode(response.body);
  }

  /// ---------------- HELPER METHODS ----------------
  static Future<bool> isAgentApproved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("is_approved") ?? false;
  }

  static Future<String?> getSpecialId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("special_id");
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<int?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("student_id");
  }
}
