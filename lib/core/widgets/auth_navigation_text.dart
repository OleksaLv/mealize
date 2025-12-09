import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AuthNavigationText extends StatelessWidget {
  const AuthNavigationText({
    super.key,
    required this.text,
    required this.buttonText,
    this.onTap,
  });

  final String text;
  final String buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Text.rich for combinating different spans with text styles in one line
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: text,
            style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
          ),
          const WidgetSpan(child: SizedBox(width: 4)),
          TextSpan(
            text: buttonText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary, 
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}