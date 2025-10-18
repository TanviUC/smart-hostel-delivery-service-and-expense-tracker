import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_models.dart';

class DeliveryApi {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // local emulator

  /// ---------------- Role-based URL helpers ----------------
  static String studentApi(String path) => "$baseUrl/student/$path";
  static String agentApi(String path) => "$baseUrl/agent/$path";
  static String adminApi(String path) => "$baseUrl/admin/$path";

  /// ---------------- Fetch stored role ----------------
  static Future<String> _getRolePrefix() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('role') ?? 'student').toLowerCase();

    switch (role) {
      case 'student':
        return studentApi("deliveries");
      case 'agent':
        return agentApi("deliveries");
      case 'admin':
        return adminApi("deliveries");
      default:
        return studentApi("deliveries");
    }
  }

  /// ---------------- Fetch token (from param or prefs) ----------------
  static Future<String> _getToken([String? token]) async {
    if (token != null && token.isNotEmpty) return token;

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token') ?? '';
    if (storedToken.isEmpty) {
      throw Exception("No token found. User might not be logged in.");
    }
    return storedToken;
  }

  /// ---------------- Fetch all deliveries ----------------
  static Future<List<DeliveryRequest>> fetchDeliveries([String? token]) async {
    final t = await _getToken(token);
    final roleUrl = await _getRolePrefix();
    print("📦 GET → $roleUrl with token=$t");

    final response = await http.get(
      Uri.parse(roleUrl),
      headers: {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List deliveries = data['data'] ?? [];
      return deliveries.map((d) => DeliveryRequest.fromJson(d)).toList();
    } else {
      throw Exception("Failed to load deliveries: ${response.body}");
    }
  }

  /// ---------------- Create new delivery ----------------
  static Future<DeliveryRequest> createDelivery(
      Map<String, dynamic> delivery, [
        String? token,
      ]) async {
    final t = await _getToken(token);
    final roleUrl = await _getRolePrefix();
    print("📦 POST → $roleUrl with token=$t");

    // Ensure alternate_receiver is JSON-encoded
    if (delivery['alternate_receiver'] != null &&
        delivery['alternate_receiver'] is Map<String, dynamic>) {
      delivery['alternate_receiver'] = jsonEncode(delivery['alternate_receiver']);
    }

    // Ensure backend-required fields exist
    final prefs = await SharedPreferences.getInstance();
    if (!delivery.containsKey('student_id')) {
      final studentId = prefs.getInt('student_id');
      if (studentId != null) delivery['student_id'] = studentId;
    }

    // If frontend uses 'amount', map to 'price'
    if (!delivery.containsKey('price') && delivery.containsKey('amount')) {
      delivery['price'] = delivery['amount'];
    }

    final response = await http.post(
      Uri.parse(roleUrl),
      headers: {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(delivery),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DeliveryRequest.fromJson(data['delivery'] ?? data['data']);
    } else {
      throw Exception("Failed to create delivery: ${response.body}");
    }
  }

  /// ---------------- Update delivery ----------------
  static Future<DeliveryRequest> updateDelivery(
      int requestId, Map<String, dynamic> updates,
      [String? token]) async {
    final t = await _getToken(token);
    final roleUrl = await _getRolePrefix();
    final url = "$roleUrl/$requestId";
    print("📦 PUT → $url with token=$t");

    if (updates['alternate_receiver'] != null &&
        updates['alternate_receiver'] is Map<String, dynamic>) {
      updates['alternate_receiver'] = jsonEncode(updates['alternate_receiver']);
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DeliveryRequest.fromJson(data['data']);
    } else {
      throw Exception("Failed to update delivery: ${response.body}");
    }
  }

  /// ---------------- Add tracking log ----------------
  static Future<void> addTrackingLog(
      int requestId, String status, {
        String? location,
        String? token,
      }) async {
    final t = await _getToken(token);
    final roleUrl = await _getRolePrefix();
    final url = "$roleUrl/$requestId/tracking";
    print("📦 POST → $url with token=$t");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "status": status,
        "location": location ?? "",
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to add tracking log: ${response.body}");
    }
  }

  /// ---------------- Add flag ----------------
  static Future<void> addFlag(
      int requestId, String flaggedBy, String reason, [
        String? token,
      ]) async {
    final t = await _getToken(token);
    final roleUrl = await _getRolePrefix();
    final url = "$roleUrl/$requestId/flag";
    print("🚩 POST → $url with token=$t");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "flagged_by": flaggedBy,
        "reason": reason,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to add flag: ${response.body}");
    }
  }
}
