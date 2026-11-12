import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/presentation/bloc/bank_bloc.dart';

class AddEditBankAccountPage extends StatefulWidget {
  final BankAccountModel? account;

  static Route route({BankAccountModel? account}) => MaterialPageRoute(
        builder: (_) => AddEditBankAccountPage(account: account),
      );

  const AddEditBankAccountPage({super.key, this.account});

  @override
  State<AddEditBankAccountPage> createState() => _AddEditBankAccountPageState();
}

class _AddEditBankAccountPageState extends State<AddEditBankAccountPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNoController;
  late final TextEditingController _branchController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _initialBalanceController;
  late final TextEditingController _routingNoController;
  late final TextEditingController _noteController;

  late bool _isActive;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _bankNameController = TextEditingController(text: a?.bankName ?? '');
    _accountNoController = TextEditingController(text: a?.accountNo ?? '');
    _branchController = TextEditingController(text: a?.branch ?? '');
    _accountNameController = TextEditingController(
      text: a != null && a.accountName.isNotEmpty ? a.accountName : 'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
    );
    _initialBalanceController = TextEditingController(
      text: a != null && a.initialBalance > 0 ? a.initialBalance.round().toString() : '',
    );
    _routingNoController = TextEditingController(text: a?.routingNo ?? '');
    _noteController = TextEditingController(text: a?.note ?? '');
    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNoController.dispose();
    _branchController.dispose();
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    _routingNoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final initialBalance = double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;

    final updated = (widget.account ??
            BankAccountModel(
              id: '',
              bankName: '',
              accountNo: '',
              createdAt: DateTime.now().toIso8601String(),
            ))
        .copyWith(
      bankName: _bankNameController.text.trim(),
      accountNo: _accountNoController.text.trim(),
      branch: _branchController.text.trim(),
      accountName: _accountNameController.text.trim(),
      initialBalance: initialBalance,
      routingNo: _routingNoController.text.trim(),
      note: _noteController.text.trim(),
      isActive: _isActive,
    );

    context.read<BankBloc>().add(BankSaveRequested(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BankBloc, BankState>(
      listener: (context, state) {
        if (state is BankActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
          Navigator.pop(context);
        } else if (state is BankFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            isEditing ? 'ব্যাংক হিসাব এডিট করুন' : 'নতুন ব্যাংক হিসাব যোগ করুন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: GradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank Name
                  CustomTextField(
                    label: 'ব্যাংকের নাম (Bank Name)',
                    hintText: 'যেমন: ইসলামী ব্যাংক বাংলাদেশ লিঃ',
                    controller: _bankNameController,
                    isRequired: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'ব্যাংকের নাম লিখুন';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Account No & Branch
                  DualFieldRow(
                    firstField: CustomTextField(
                      label: 'হিসাব নম্বর (A/C No)',
                      hintText: 'যেমন: ২০৫০১০১০০২২৫৫৮',
                      controller: _accountNoController,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'হিসাব নম্বর লিখুন';
                        return null;
                      },
                    ),
                    lastField: CustomTextField(
                      label: 'শাখার নাম (Branch)',
                      hintText: 'যেমন: নোয়াপাড়া শাখা',
                      controller: _branchController,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Name & Routing No
                  DualFieldRow(
                    firstField: CustomTextField(
                      label: 'হিসাবের শিরোনাম (A/C Name)',
                      hintText: 'যেমন: সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
                      controller: _accountNameController,
                    ),
                    lastField: CustomTextField(
                      label: 'রাউটিং নং (Routing No)',
                      hintText: 'ঐচ্ছিক',
                      controller: _routingNoController,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Initial Balance (প্রারম্ভিক স্থিতি)
                  CustomTextField(
                    label: 'প্রারম্ভিক স্থিতি (Initial Balance / ৳)',
                    hintText: 'যেমন: 50000 (খোলার সময়ের নগদ ব্যালেন্স)',
                    controller: _initialBalanceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditing
                        ? 'সতর্কতা: প্রারম্ভিক স্থিতি পরিবর্তন করলে বর্তমান সার্বিক ব্যালেন্স পুনর্গণনা হবে'
                        : 'ব্যাংকটি অ্যাপে যুক্ত করার সময় উক্ত একাউন্টে বিদ্যমান ব্যালেন্স',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note / Description
                  CustomTextField(
                    label: 'বিবরণ / নোট',
                    hintText: 'হিসাব সংক্রান্ত কোনো বিশেষ তথ্য বা বিবরণ...',
                    controller: _noteController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Status Selector (Active / Inactive)
                  Text(
                    'অ্যাকাউন্ট স্ট্যাটাস',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SelectableChip(
                        label: 'সক্রিয় (Active)',
                        isSelected: _isActive,
                        onSelected: () => setState(() => _isActive = true),
                      ),
                      const SizedBox(width: 10),
                      SelectableChip(
                        label: 'নিষ্ক্রিয় (Inactive)',
                        isSelected: !_isActive,
                        onSelected: () => setState(() => _isActive = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  BlocBuilder<BankBloc, BankState>(
                    builder: (context, state) {
                      final isLoading = state is BankLoading;
                      return SpringButton(
                        width: double.infinity,
                        onPressed: isLoading ? null : _saveAccount,
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                    size: 20,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing ? 'পরিবর্তন সংরক্ষণ করুন' : 'ব্যাংক হিসাব যুক্ত করুন',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
