import 'package:flutter/material.dart';

const primaryBlue = Color(0xFF4B63FF);
const textMuted = Color(0xFF8E9AB8);
const fieldFill = Color(0xFFF6F8FC);
const textDark = Color(0xFF1B1F2A);

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: index <= activeIndex ? primaryBlue : const Color(0xFFE9EEF8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

InputDecoration buildFieldDecoration(String hint) {
  return InputDecoration(
    filled: true,
    fillColor: fieldFill,
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB7C0D9)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

TextStyle fieldTextStyle() => const TextStyle(color: textDark);
