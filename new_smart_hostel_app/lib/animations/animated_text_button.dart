import 'package:flutter/material.dart';

class AnimatedTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedTextButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    );
  }
}
