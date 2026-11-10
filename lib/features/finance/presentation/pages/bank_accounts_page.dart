import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';

class BankAccountsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const BankAccountsPage());

  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  final List<Map<String, dynamic>> _accounts = [
    {
      'id': 'b1',
      'bankName': 'ইসলামী ব্যাংক বাংলাদেশ লিঃ',
      'branch': 'নোয়াপাড়া শাখা',
      'acctNo': '২০৫০১০১০০২২৫৫৮',
      'balance': 385000.0,
    },
    {
      'id': 'b2',
      'bankName': 'সোনালী ব্যাংক পিএলসি',
      'branch': 'বাগোয়ান শাখা',
      'acctNo': '০১০৩২০১০০৫৫৮৬',
      'balance': 150000.0,
    },
  ];

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final totalBank = _accounts.fold<double>(0, (s, a) => s + (a['balance'] as double));

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'ব্যাংক হিসাব ও নগদ লেনদেন',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircleHalfDot, size: 22, color: AppColors.primary),
            onPressed: _showAddAccountDialog,
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Bank Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF640710), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ব্যাংক সমূহের মোট সঞ্চয় স্থিতি',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatAmount(totalBank),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons: Deposit vs Withdraw
              Row(
                children: [
                  Expanded(
                    child: SpringButton(
                      onPressed: () => _showTransferDialog(isDeposit: true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedArrowDownLeft01, size: 18, color: AppColors.white),
                          const SizedBox(width: 8),
                          Text(
                            'ব্যাংকে জমা',
                            style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SpringButton(
                      onPressed: () => _showTransferDialog(isDeposit: false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedArrowUpRight01, size: 18, color: AppColors.white),
                          const SizedBox(width: 8),
                          Text(
                            'ব্যাংক থেকে উত্তোলন',
                            style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'সংযুক্ত ব্যাংক অ্যাকাউন্টসমূহ',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _accounts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final acct = _accounts[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedBank,
                              size: 24,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acct['bankName'],
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${acct['branch']} • হিসাব নং: ${acct['acctNo']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatAmount(acct['balance']),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferDialog({required bool isDeposit}) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isDeposit ? 'নগদ থেকে ব্যাংকে জমা' : 'ব্যাংক থেকে নগদ উত্তোলন',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'টাকার পরিমাণ',
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              hintText: 'যেমন: 20000',
              isRequired: true,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'বিবরণ / নোট',
              controller: noteCtrl,
              hintText: 'যেমন: ব্যাংক জমা স্লিপ নং ১২৩',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amount <= 0) {
                AppNotifier.showErrorSnackBar(ctx, 'সঠিক পরিমাণ দিন');
                return;
              }

              try {
                final nextVNo = await TransactionsRepo.getNextVoucherNo();
                final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

                final trx = TransactionModel(
                  id: '',
                  vno: nextVNo,
                  date: date,
                  type: isDeposit ? 'bank_dep' : 'bank_wd',
                  amount: amount,
                  mode: 'bank',
                  note: noteCtrl.text.trim(),
                );

                await TransactionsRepo.addTransaction(trx);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  AppNotifier.showSuccessSnackBar(context, 'ভাউচার সফলভাবে তৈরি হয়েছে');
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppNotifier.showErrorSnackBar(ctx, 'লেনদেন সংরক্ষণ ব্যর্থ: $e');
                }
              }
            },
            child: const Text('নিশ্চিত করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog() {
    final nameCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    final acctCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'নতুন ব্যাংক হিসাব যুক্ত করুন',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(label: 'ব্যাংকের নাম', controller: nameCtrl, isRequired: true),
            const SizedBox(height: 10),
            CustomTextField(label: 'শাখার নাম', controller: branchCtrl),
            const SizedBox(height: 10),
            CustomTextField(label: 'হিসাব নম্বর (A/C No)', controller: acctCtrl, isRequired: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || acctCtrl.text.trim().isEmpty) {
                AppNotifier.showErrorSnackBar(ctx, 'নাম ও হিসাব নম্বর দিন');
                return;
              }
              setState(() {
                _accounts.add({
                  'id': 'b_${DateTime.now().millisecondsSinceEpoch}',
                  'bankName': nameCtrl.text.trim(),
                  'branch': branchCtrl.text.trim(),
                  'acctNo': acctCtrl.text.trim(),
                  'balance': 0.0,
                });
              });
              Navigator.pop(ctx);
              AppNotifier.showSuccessSnackBar(context, 'ব্যাংক হিসাব যুক্ত করা হয়েছে');
            },
            child: const Text('যুক্ত করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
