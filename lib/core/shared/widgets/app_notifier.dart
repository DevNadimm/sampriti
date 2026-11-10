import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/utils/enums/message_type.dart';

class AppNotifier {
  static ContentType _getContentType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return ContentType.success;
      case MessageType.error:
        return ContentType.failure;
      case MessageType.warning:
        return ContentType.warning;
      case MessageType.info:
        return ContentType.help;
    }
  }

  static Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return AppColors.success;
      case MessageType.error:
        return AppColors.error;
      case MessageType.info:
        return AppColors.info;
      case MessageType.warning:
        return AppColors.warning;
    }
  }

  static IconData _getIconData(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
      case MessageType.warning:
        return Icons.warning;
    }
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, type: MessageType.success);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, type: MessageType.error);
  }

  /// Show normal Material SnackBar
  static void showSnackBar(BuildContext context, String message, {MessageType type = MessageType.info}) {
    final bgColor = _getBackgroundColor(type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_getIconData(type), color: AppColors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Show Awesome SnackBar
  static void showAwesomeSnackBar(
    BuildContext context,
    String title,
    String message, {
    MessageType type = MessageType.info,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 4),
      content: AwesomeSnackbarContent(
        title: title, // Maximum 22 character long title
        message: message, // Maximum 80 character long message
        contentType: _getContentType(type),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show Awesome Material Banner
  static void showAwesomeMaterialBanner(
    BuildContext context,
    String title,
    String message, {
    MessageType type = MessageType.info,
  }) {
    final banner = MaterialBanner(
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: _getContentType(type),
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(banner);
  }

  /// Show dialog message
  static void showDialogMessage(
    BuildContext context, {
    required String title,
    required String message,
    MessageType type = MessageType.info,
  }) {
    final titleColor = _getBackgroundColor(type);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: TextStyle(color: titleColor)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
