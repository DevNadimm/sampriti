import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/custom_icon_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/features/auth/data/repos/auth_repo.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/auth/presentation/pages/login_page.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool isAdmin;
  final String? photoUrl;
  final String? memberNo;
  final VoidCallback? onAvatarTap;

  const DashboardAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isAdmin,
    this.photoUrl,
    this.memberNo,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap ?? (isAdmin ? () => _showChangePasswordDialog(context) : null),
            behavior: HitTestBehavior.opaque,
            child: isAdmin
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.inputBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedShieldUser,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : MemberAvatar(
                    photo: photoUrl,
                    fallbackText: memberNo ?? 'S',
                    size: 46,
                    isCircle: true,
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAdmin ? 'আসসালামু আলাইকুম' : 'স্বাগতম',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isAdmin ? AppColors.primary : AppColors.accent).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isAdmin ? AppColors.primary : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CustomIconButton(
              size: 40,
              iconSize: 20,
              tooltip: 'পাসওয়ার্ড পরিবর্তন',
              backgroundColor: AppColors.card,
              shape: const CircleBorder(side: BorderSide(color: AppColors.inputBorder, width: 1)),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedLockPassword,
                size: 20,
                color: AppColors.primary,
              ),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CustomIconButton(
            size: 40,
            iconSize: 20,
            tooltip: 'লগআউট',
            backgroundColor: AppColors.card,
            shape: const CircleBorder(side: BorderSide(color: AppColors.inputBorder, width: 1)),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout03,
              size: 20,
              color: AppColors.error,
            ),
            onTap: () {
              AppConfirmationDialog.show(
                context,
                title: 'লগআউট',
                message: 'আপনি কি নিশ্চিত যে অ্যাপ থেকে লগআউট করতে চান?',
                confirmText: 'লগআউট',
                isDestructive: true,
                onConfirm: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.pushAndRemoveUntil(
                    context,
                    LoginPage.route(),
                    (route) => false,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedLockPassword,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'অ্যাডমিন পাসওয়ার্ড পরিবর্তন',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'উচ্চ নিরাপত্তার জন্য পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং বড়-ছোট হাতের অক্ষর, সংখ্যা ও স্পেশাল ক্যারেক্টার থাকতে হবে।',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'বর্তমান পাসওয়ার্ড',
                        controller: currentPwController,
                        obscureText: true,
                        hintText: 'বর্তমান পাসওয়ার্ড লিখুন',
                        prefixIcon: HugeIcons.strokeRoundedSquareLock02,
                        validator: (val) {
                          if (val == null || val.toString().trim().isEmpty) {
                            return 'বর্তমান পাসওয়ার্ড দিন';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'নতুন পাসওয়ার্ড',
                        controller: newPwController,
                        obscureText: true,
                        hintText: 'নতুন পাসওয়ার্ড লিখুন',
                        prefixIcon: HugeIcons.strokeRoundedKey01,
                        validator: (val) {
                          final v = val?.toString().trim() ?? '';
                          if (v.length < 8) return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
                          if (!v.contains(RegExp(r'[A-Z]'))) return 'কমপক্ষে ১টি বড় হাতের অক্ষর (A-Z) থাকতে হবে';
                          if (!v.contains(RegExp(r'[a-z]'))) return 'কমপক্ষে ১টি ছোট হাতের অক্ষর (a-z) থাকতে হবে';
                          if (!v.contains(RegExp(r'[0-9]'))) return 'কমপক্ষে ১টি সংখ্যা (0-9) থাকতে হবে';
                          if (!v.contains(RegExp(r'[!@#\$&*~._-]'))) return 'কমপক্ষে ১টি বিশেষ চিহ্ন (!@#\$&*~._-) থাকতে হবে';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'নতুন পাসওয়ার্ড নিশ্চিত করুন',
                        controller: confirmPwController,
                        obscureText: true,
                        hintText: 'পুনরায় নতুন পাসওয়ার্ড লিখুন',
                        prefixIcon: HugeIcons.strokeRoundedCheckmarkBadge01,
                        validator: (val) {
                          if (val?.toString().trim() != newPwController.text.trim()) {
                            return 'নতুন পাসওয়ার্ড মেলেনি';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'বাতিল',
                    style: GoogleFonts.notoSansBengali(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setDialogState(() => isLoading = true);
                          try {
                            await AuthRepo.changeAdminPassword(
                              currentPassword: currentPwController.text.trim(),
                              newPassword: newPwController.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              AppNotifier.showSuccessSnackBar(
                                context,
                                'অ্যাডমিন পাসওয়ার্ড সফলভাবে পরিবর্তিত হয়েছে',
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (ctx.mounted) {
                              AppNotifier.showErrorSnackBar(ctx, e.toString());
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'পরিবর্তন করুন',
                          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
