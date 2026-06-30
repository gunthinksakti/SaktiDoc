import 'package:flutter/material.dart';

class CustomDialog {
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(body, style: TextStyle(color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
}
