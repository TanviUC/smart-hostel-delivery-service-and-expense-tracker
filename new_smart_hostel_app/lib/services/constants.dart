import 'dart:io';
import 'package:flutter/material.dart';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android Emulator → host machine
      return "http://10.0.2.2:8000/api";
    } else if (Platform.isIOS) {
      // iOS Simulator → host machine
      return "http://127.0.0.1:8000/api";
    } else {
      // Real devices (or web)
      // 🔹 Replace with your machine's LAN IP or production server
      return "http://192.168.1.5:8000/api";
      // e.g. return "https://yourdomain.com/api";
    }
  }
}

    class AppColors {
    static const Color blue = Color(0xFF7DD3FC);
    static const Color blueDark = Color(0xFF38BDF8);
    static const Color cardBg = Color(0xFF0F172A);
    }

