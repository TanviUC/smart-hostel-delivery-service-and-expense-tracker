import 'package:flutter/material.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "📦 Requests Page",
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
      ),
    );
  }
}
