import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/core/utils/helpers/date_picker_helper.dart';
import 'package:sampriti/core/utils/helpers/option_picker_bottom_sheet_helper.dart';
import 'package:sampriti/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/data/repos/bank_repo.dart';
import 'package:sampriti/features/finance/presentation/bloc/bank_bloc.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';
import 'package:sampriti/features/transactions/presentation/pages/voucher_details_page.dart';

class BankTransferPage extends StatefulWidget {
  final bool initialIsDeposit;

  static Route route({bool isDeposit = true}) => MaterialPageRoute(
        builder: (_) => BankTransferPage(initialIsDeposit: isDeposit),
      );

  const BankTransferPage({super.key, this.initialIsDeposit = true});

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage> {
  final _formKey = GlobalKey<FormState>();

  late bool _isDeposit;

  final _bankController = TextEditingController();
  final _amountController = TextEditingController();
  final _slipNoController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateFormatter.ddMMyyyy(DateTime.now()),
  );
  final _noteController = TextEditingController();

  List<BankAccountModel> _accounts = [];
  BankAccountModel? _selectedAccount;
  double _cashBalance = 0.0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<TransactionModel> _recentTransfers = [];

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  void initState() {
    super.initState();
    _isDeposit = widget.initialIsDeposit;
    _loadData();
  }

  @override
  void dispose() {
    _bankController.dispose();
    _amountController.dispose();
    _slipNoController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await BankRepo.getBankAccounts();
      final fund = await BankRepo.getFundSummary();
      final allTx = await TransactionsRepo.getTransactions();

      final transfers = allTx
          .where((t) => t.isBankTransfer)
          .take(10)
          .toList();

      if (mounted) {
        setState(() {
          _accounts = accounts.where((a) => a.isActive).toList();
          if (_accounts.isNotEmpty) {
            _selectedAccount = _accounts.first;
            _bankController.text = _selectedAccount!.displayName;
          }
          _cashBalance = fund['cashBalance'] ?? 0.0;
          _recentTransfers = transfers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifier.showErrorSnackBar(context, 'ডাটা লোড ব্যর্থ: $e');
      }
    }
  }

  void _openBankPicker() {
    if (_accounts.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'কোনো সক্রিয় ব্যাংক হিসাব নেই');
      return;
    }

    OptionPickerBottomSheetHelper.show(
      context: context,
      title: _isDeposit ? 'জমার ব্যাংক নির্বাচন করুন' : 'উত্তোলনের ব্যাংক নির্বাচন করুন',
      options: _accounts.map((a) => a.displayName).toList(),
      controller: _bankController,
      onSelect: (selectedName) {
        setState(() {
          _selectedAccount = _accounts.firstWhere(
            (a) => a.displayName == selectedName,
            orElse: () => _accounts.first,
          );
          _bankController.text = _selectedAccount!.displayName;
        });
      },
    );
  }

  Future<void> _submitTransfer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedAccount == null) {
      AppNotifier.showErrorSnackBar(context, 'একটি ব্যাংক হিসাব নির্বাচন করুন');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppNotifier.showErrorSnackBar(context, 'সঠিক টাকার পরিমাণ দিন');
      return;
    }

    // Balance checks
    if (!_isDeposit && amount > _selectedAccount!.currentBalance) {
      AppNotifier.showErrorSnackBar(
        context,
        'উক্ত ব্যাংকে পর্যাপ্ত ব্যালেন্স নেই। সর্বোচ্চ তোলার সুযোগ: ${_formatAmount(_selectedAccount!.currentBalance)}',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final trx = await BankRepo.recordBankTransfer(
        isDeposit: _isDeposit,
        bankId: _selectedAccount!.id,
        amount: amount,
        date: _dateController.text.trim(),
        slipNo: _slipNoController.text.trim(),
        note: _noteController.text.trim(),
      );

      if (mounted) {
        AppNotifier.showSuccessSnackBar(
          context,
          _isDeposit
              ? 'ব্যাংকে জমা সফলভাবে সম্পন্ন হয়েছে (ভাউচার: ${trx.vno})'
              : 'ব্যাংক থেকে উত্তোলন সফল হয়েছে (ভাউচার: ${trx.vno})',
        );

        // Notify global BLoCs
        context.read<BankBloc>().add(BankFetchRequested());
        context.read<DashboardBloc>().add(DashboardFetchRequested());

        // Clear input form and reload
        _amountController.clear();
        _slipNoController.clear();
        _noteController.clear();
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.showErrorSnackBar(context, 'লেনদেন ব্যর্থ হয়েছে: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'ব্যাংক জমা ও উত্তোলন',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: Loader())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Sleek Segmented Switcher (Deposit vs Withdraw)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegmentTab(
                                title: 'ব্যাংকে জমা',
                                icon: HugeIcons.strokeRoundedArrowDownLeft01,
                                isSelected: _isDeposit,
                                activeColor: AppColors.primary,
                                onTap: () => setState(() => _isDeposit = true),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _SegmentTab(
                                title: 'ব্যাংক থেকে উত্তোলন',
                                icon: HugeIcons.strokeRoundedArrowUpRight01,
                                isSelected: !_isDeposit,
                                activeColor: AppColors.primaryDark,
                                onTap: () => setState(() => _isDeposit = false),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Fund & Bank Balance Overview Card (RentBook Clean Style)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            // Cash in Hand Info
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedWallet02,
                                      size: 20,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'নগদ ক্যাশ স্থিতি',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatAmount(_cashBalance),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: _cashBalance >= 0 ? AppColors.textPrimary : AppColors.error,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 32,
                              width: 1,
                              color: AppColors.border,
                            ),
                            const SizedBox(width: 12),

                            // Selected Bank Balance Info
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedBank,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ব্যাংক ব্যালেন্স',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatAmount(_selectedAccount?.currentBalance ?? 0.0),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. Bank Account Selection Field (OptionPickerBottomSheetHelper)
                      CustomTextField(
                        label: _isDeposit ? 'যে ব্যাংক হিসাবে জমা হবে' : 'যে ব্যাংক হিসাব হতে তোলা হবে',
                        controller: _bankController,
                        readOnly: true,
                        isRequired: true,
                        hintText: 'ব্যাংক হিসাব নির্বাচন করুন',
                        suffixIcon: HugeIcons.strokeRoundedArrowDown01,
                        onTap: _openBankPicker,
                      ),
                      const SizedBox(height: 16),

                      // 4. Amount Input Field
                      CustomTextField(
                        label: 'টাকার পরিমাণ (৳)',
                        hintText: 'যেমন: 25000',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'টাকার পরিমাণ লিখুন';
                          final numVal = double.tryParse(v.trim());
                          if (numVal == null || numVal <= 0) return 'সঠিক পরিমাণ দিন';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 5. Slip No & Date
                      DualFieldRow(
                        firstField: CustomTextField(
                          label: _isDeposit ? 'ডিপোজিট স্লিপ নং' : 'চেক নম্বর / ভাউচার',
                          hintText: _isDeposit ? 'যেমন: স্লিপ ১২৮৮' : 'যেমন: চেক নং খখ-৫৫৮৭৪',
                          controller: _slipNoController,
                        ),
                        lastField: CustomTextField(
                          label: 'লেনদেনের তারিখ',
                          controller: _dateController,
                          readOnly: true,
                          suffixIcon: HugeIcons.strokeRoundedCalendar03,
                          onTap: () async {
                            await DatePickerHelper.show(
                              context: context,
                              controller: _dateController,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 6. Note Field
                      CustomTextField(
                        label: 'বিবরণ / নোট (ঐচ্ছিক)',
                        hintText: 'প্রয়োজনে লেনদেন সংক্রান্ত কোনো বিশেষ তথ্য...',
                        controller: _noteController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // 7. Submit Action Button
                      SpringButton(
                        width: double.infinity,
                        onPressed: _isSubmitting ? null : _submitTransfer,
                        child: _isSubmitting
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
                                  HugeIcon(
                                    icon: _isDeposit
                                        ? HugeIcons.strokeRoundedArrowDownLeft01
                                        : HugeIcons.strokeRoundedArrowUpRight01,
                                    size: 20,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isDeposit ? 'ব্যাংকে জমা সম্পন্ন করুন' : 'ব্যাংক থেকে উত্তোলন সম্পন্ন করুন',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 28),

                      // 8. Recent Transfer Activity
                      if (_recentTransfers.isNotEmpty) ...[
                        Text(
                          'সাম্প্রতিক ব্যাংক ট্রান্সফার লেনদেন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentTransfers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = _recentTransfers[index];
                            final isDep = tx.kind == 'bank_dep';
                            return CustomContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              onTap: () => Navigator.push(
                                context,
                                VoucherDetailsPage.route(transaction: tx),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (isDep ? AppColors.success : AppColors.primary)
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: HugeIcon(
                                      icon: isDep
                                          ? HugeIcons.strokeRoundedArrowDownLeft01
                                          : HugeIcons.strokeRoundedArrowUpRight01,
                                      size: 16,
                                      color: isDep ? AppColors.success : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${tx.uiDate} • ভাউচার: ${tx.vno}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatAmount(tx.amount),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDep ? AppColors.success : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 17,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.notoSansBengali(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
