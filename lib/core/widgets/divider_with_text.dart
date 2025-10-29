import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  const DividerWithText({
    super.key,
    required this.text,
  });

  /// Текст, що відображатиметься посередині
  final String text;

  @override
  Widget build(BuildContext context) {
    // Віджет-розділювач, щоб не дублювати код
    final divider = Expanded(
      child: Divider(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Лінія зліва
        divider,
        // Текст з відступами
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Лінія справа
        divider,
      ],
    );
  }
}