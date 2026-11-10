import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sampriti/core/config/colors.dart';

class ImagePickerHelper {
  static final _picker = ImagePicker();

  /// Pick image, resize to 280x360 at 82% quality (matching HTML spec) and return base64 data URI
  static Future<String?> pickImageAsBase64(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 280,
        maxHeight: 360,
        imageQuality: 82,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Show bottom sheet options to take photo from camera, gallery or delete
  static Future<void> showPickerOptions({
    required BuildContext context,
    required String title,
    bool showDelete = false,
    required Function(String base64) onImageSelected,
    VoidCallback? onDelete,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'ক্যামেরা দিয়ে ছবি তুলুন',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final img = await pickImageAsBase64(ImageSource.camera);
                  if (img != null) onImageSelected(img);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedImage02,
                    size: 22,
                    color: AppColors.info,
                  ),
                ),
                title: Text(
                  'গ্যালারি থেকে ছবি বাছুন',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final img = await pickImageAsBase64(ImageSource.gallery);
                  if (img != null) onImageSelected(img);
                },
              ),
              if (showDelete && onDelete != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: 22,
                      color: AppColors.error,
                    ),
                  ),
                  title: Text(
                    'ছবি মুছে ফেলুন',
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
