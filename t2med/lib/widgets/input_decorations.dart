import 'package:flutter/material.dart';

class InputDecorations {
  static InputDecoration inputDecorations({
    required String hintText,
    required String labelText,
    required Icon prefixIcon,
  }) {
    return InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepPurple),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }
}
