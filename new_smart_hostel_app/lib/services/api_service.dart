import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  /// ---------------- SAVE USER DATA LOCALLY ----------------
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.containsKey("token")) {
      await prefs.setString("token", data["token"]);
    }

    if (data.containsKey("user")) {
      final user = data["user"];
      await prefs.setString("name", user["name"] ?? "");
      await prefs.setString("email", user["email"] ?? "");
      await prefs.setString("role", (user["role"] ?? "").toString().toLowerCase());

      if (user.containsKey("is_approved")) {
        await prefs.setBool(
          "is_approved",
          user["is_approved"] == 1 || user["is_approved"] == true,
        );
      }

      if (user.containsKey("special_id")) {
        await prefs.setString("special_id", user["special_id"]);
      }

      if (user.containsKey("unique_id")) {
        await prefs.setString("unique_id", user["unique_id"]);
      }
    }
  }

  /// ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login(
      String email, String password, String role,
      {String? uniqueId, bool useGenericAuth = false}) async {

    final endpoint = useGenericAuth ? 'auth/login' : '$role/login';
    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    final body = {
      'email': email,
      'password': password,
      'role': role,
      if (role.toLowerCase() == "agent" && uniqueId != null) 'unique_id': uniqueId,
    };

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveUserData(data);
      return data;
    } else {
      throw Exception("Login failed: ${data['message'] ?? response.body}");
    }
  }

  /// ---------------- REGISTER ----------------
  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password, {
        required String role,
        String? uniqueId,
        bool useGenericAuth = false,
      }) async {
    try {
      final endpoint = useGenericAuth ? 'auth/register' : '$role/register';
      final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

      // Build request body
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
        if (role.toLowerCase() == "agent" && uniqueId != null) 'unique_id': uniqueId,
      };

      // Send POST request
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save user info locally
        await _saveUserData(data);
        return {
          "success": true,
          "message": data["message"] ?? "Registered successfully",
          "data": data,
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Registration failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }


  /// ---------------- LOGOUT ----------------
  Future<void> logout({String? role, bool useGenericAuth = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    String endpoint = useGenericAuth
        ? 'auth/logout'
        : (role != null ? '$role/logout' : 'auth/logout');

    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    await http.post(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    await prefs.clear();
  }

  /// ---------------- CURRENT USER ----------------
  Future<Map<String, dynamic>> getCurrentUser({String? role, bool useGenericAuth = false}) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found");

    String endpoint = useGenericAuth
        ? 'auth/me'
        : (role != null ? '$role/details' : 'auth/me');

    final url = Uri.parse("${ApiConstants.baseUrl}/$endpoint");

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Fetch user failed: ${response.body}");
    }
  }

  /// ---------------- PASSWORD RESET ----------------
  Future<Map<String, dynamic>> requestPasswordReset(String email, String role) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/$role/password/forgot");

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Request failed: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset(
      String email, String otp, String newPassword, String role) async {

    final url = Uri.parse("${ApiConstants.baseUrl}/$role/password/reset");

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'password': newPassword}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Reset failed: ${response.body}");
    }
  }

  /// ---------------- UNIQUE ID RECOVERY (Agent only) ----------------
  Future<Map<String, dynamic>> forgotUniqueId(String email) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/agent/forgot-id");

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Forgot ID failed: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> resetUniqueId(String email, String otp, {String? newUniqueId}) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/agent/forgot-id/reset");

    final body = {'email': email, 'otp': otp, if (newUniqueId != null && newUniqueId.isNotEmpty) 'unique_id': newUniqueId};

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Reset ID failed: ${response.body}");
    }
  }

  /// ---------------- DELIVERIES ----------------

  Future<List<Map<String, dynamic>>> getDeliveries(String token) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/deliveries");

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final deliveries = json['data'] ?? [];
      return List<Map<String, dynamic>>.from(deliveries);
    } else {
      throw Exception("Failed to fetch deliveries: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createDelivery(String token, Map<String, dynamic> payload) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/deliveries");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception("Failed to create delivery: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateDelivery(String token, int id, Map<String, dynamic> updates) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/deliveries/$id");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception("Failed to update delivery: ${response.body}");
    }
  }

  Future<void> addTrackingLog(String token, int id, String status, {String? location}) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/deliveries/$id/tracking");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"status": status, "location": location ?? ""}),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to add tracking log: ${response.body}");
    }
  }

  Future<void> addFlag(String token, int id, String flaggedBy, String reason) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/deliveries/$id/flag");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"flagged_by": flaggedBy, "reason": reason}),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to add flag: ${response.body}");
    }
  }

  Future<void> deleteDelivery(String token, int id) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/deliveries/$id");

    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete delivery: ${response.body}");
    }
  }

  /// ---------------- PASSWORD RESET ALIASES ----------------
  /// For backward compatibility with your ForgotPasswordScreen
  Future<Map<String, dynamic>> forgotPassword(String email, String role) async {
    return requestPasswordReset(email, role);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp, String role) async {
    /// Just verify OTP by calling confirmPasswordReset with temp password
    return confirmPasswordReset(email, otp, "TempPass123!", role);
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword, String role) async {
    return confirmPasswordReset(email, otp, newPassword, role);
  }


  /// ---------------- FEEDBACK ----------------
  Future<List<dynamic>> getFeedbacks() async {
    final token = await getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/feedback");

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception("Failed to fetch feedbacks: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createFeedback(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/feedback");

    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create feedback: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateFeedback(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/feedback/$id");

    final response = await http.put(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update feedback: ${response.body}");
    }
  }

  Future<void> deleteFeedback(int id) async {
    final token = await getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/feedback/$id");

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete feedback: ${response.body}");
    }
  }

  /// ---------------- LOCAL STORAGE HELPERS ----------------
  static Future<String?> getToken() async => (await SharedPreferences.getInstance()).getString("token");
  static Future<String?> getRole() async => (await SharedPreferences.getInstance()).getString("role");
  static Future<String?> getName() async => (await SharedPreferences.getInstance()).getString("name");
  static Future<String?> getEmail() async => (await SharedPreferences.getInstance()).getString("email");
  static Future<String?> getSpecialId() async => (await SharedPreferences.getInstance()).getString("special_id");
  static Future<String?> getUniqueId() async => (await SharedPreferences.getInstance()).getString("unique_id");
  static Future<bool> isApprovedAgent() async => (await SharedPreferences.getInstance()).getBool("is_approved") ?? false;
  static Future<void> clearAll() async => await (await SharedPreferences.getInstance()).clear();
}
