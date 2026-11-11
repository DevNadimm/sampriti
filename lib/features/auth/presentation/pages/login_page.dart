import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/app_developer_footer.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/auth/data/repos/auth_repo.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/dashboard/presentation/pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const LoginPage());

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _selectedTab = 0; // 0: Shareholder, 1: Admin

  // Shareholder Controllers (No pre-defined text for security)
  final _shareNoController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  // Admin Controller (No pre-defined text for security)
  final _adminPwController = TextEditingController();
  bool _obscureAdminPw = true;

  final _shareholderFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Invalidate any leftover cached session when landing on login screen
    AuthRepo.logout();
  }

  @override
  void dispose() {
    _shareNoController.dispose();
    _pinController.dispose();
    _adminPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          AppNotifier.showSuccessSnackBar(
            context,
            'স্বাগতম, ${state.session.name}!',
          );
          Navigator.pushReplacement(context, DashboardPage.route());
        } else if (state is AuthFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Stack(
          children: [
            Scaffold(
              body: GradientBackground(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sampriti Logo Emblem
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                Assets.appLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'স্বচ্ছতা ও সমৃদ্ধির অংশীদারী প্ল্যাটফর্ম',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Card Container for Tabs and Forms
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Segmented Tab Selector
                                _buildSegmentedTab(),
                                const SizedBox(height: 20),

                                // Smooth in-place CrossFade (Never clips screen padding)
                                AnimatedCrossFade(
                                  firstChild: _buildShareholderForm(isLoading),
                                  secondChild: _buildAdminForm(isLoading),
                                  crossFadeState: _selectedTab == 0
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  duration: const Duration(milliseconds: 250),
                                  firstCurve: Curves.easeInOut,
                                  secondCurve: Curves.easeInOut,
                                  sizeCurve: Curves.easeInOut,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const AppDeveloperFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: AppColors.black.withValues(alpha: 0.6),
                child: const Loader(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTab != 0) {
                  setState(() => _selectedTab = 0);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      size: 17,
                      color: _selectedTab == 0 ? AppColors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'শেয়ারহোল্ডার',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedTab == 0 ? AppColors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTab != 1) {
                  setState(() => _selectedTab = 1);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      size: 17,
                      color: _selectedTab == 1 ? AppColors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'অ্যাডমিন',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedTab == 1 ? AppColors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareholderForm(bool isLoading) {
    return Form(
      key: _shareholderFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'শেয়ার নম্বর (Share ID)',
            controller: _shareNoController,
            isRequired: true,
            hintText: 'যেমন: S101',
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'গোপন পিন কোড (PIN)',
            controller: _pinController,
            isRequired: true,
            hintText: '৪-৬ ডিজিটের পিন নম্বর',
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            suffixIcon: _obscurePin
                ? HugeIcons.strokeRoundedViewOffSlash
                : HugeIcons.strokeRoundedView,
            onSuffixTap: () => setState(() => _obscurePin = !_obscurePin),
          ),
          const SizedBox(height: 10),
          Text(
            '* পরিচালনা পর্ষদ / অ্যাডমিন কর্তৃক প্রদত্ত ৪-ডিজিটের গোপন পিন ব্যবহার করুন।',
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          SpringButton(
            width: double.infinity,
            onPressed: isLoading ? null : _submitShareholder,
            child: Text(
              'লগইন করুন',
              style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm(bool isLoading) {
    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'মাস্টার পাসওয়ার্ড (Master Password)',
            controller: _adminPwController,
            isRequired: true,
            hintText: 'অ্যাডমিন মাস্টার পাসওয়ার্ড লিখুন',
            obscureText: _obscureAdminPw,
            suffixIcon: _obscureAdminPw
                ? HugeIcons.strokeRoundedViewOffSlash
                : HugeIcons.strokeRoundedView,
            onSuffixTap: () => setState(() => _obscureAdminPw = !_obscureAdminPw),
          ),
          const SizedBox(height: 12),
          Text(
            '* অ্যাডমিন ড্যাশবোর্ড কেবল পরিচালনা পর্ষদের জন্য সংরক্ষিত।',
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          SpringButton(
            width: double.infinity,
            onPressed: isLoading ? null : _submitAdmin,
            child: Text(
              'অ্যাডমিন প্যানেলে প্রবেশ',
              style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _submitShareholder() {
    if (!(_shareholderFormKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
          ShareholderLoginRequested(
            shareNo: _shareNoController.text.trim(),
            pin: _pinController.text.trim(),
          ),
        );
  }

  void _submitAdmin() {
    if (!(_adminFormKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
          AdminLoginRequested(_adminPwController.text.trim()),
        );
  }
}
