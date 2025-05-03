import 'package:flutter/material.dart';

SnackBar buildCustomSnackBar(
    String message, {
      String? actionLabel,
      VoidCallback? actionOnPressed,
    }) {
  return SnackBar(
    content: Text(
      message,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    backgroundColor: const Color(0xFF00A99D), // Theme primary color
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    duration: const Duration(milliseconds: 500), // 500ms duration
    elevation: 6,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    action: actionLabel != null && actionOnPressed != null
        ? SnackBarAction(
      label: actionLabel,
      onPressed: actionOnPressed,
      textColor: Colors.white,
    )
        : null,
  );
}