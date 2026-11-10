import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/core/utils/helpers/date_picker_helper.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';

class BulkPayoutPage extends StatefulWidget {
  final double availableProfit;

  static Route route({required double availableProfit}) => MaterialPageRoute(
        builder: (_) => BulkPayoutPage(availableProfit: availableProfit),
      );

  const BulkPayoutPage({super.key, required this.availableProfit});

  @override
  State<BulkPayoutPage> createState() => _BulkPayoutPageState();
}

class _BulkPayoutPageState extends State<BulkPayoutPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fundController;
  late final TextEditingController _dateController;
  late final TextEditingController _noteController;
  String _mode = 'cash';
  double _founderPct = 20;
  double _laborPct = 20;
  double _mainFundPct = 60;

  @override
  void initState() {
    super.initState();
    _fundController = TextEditingController(
      text: widget.availableProfit > 0 ? widget.availableProfit.round().toString() : '50000',
    );
    _dateController = TextEditingController(
      text: DateFormatter.ddMMyyyy(DateTime.now()),
    );
    _noteController = TextEditingController(text: 'মুনাফা বণ্টন');
    _loadOrgConfig();
  }

  Future<void> _loadOrgConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('org_config').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _founderPct = ((data['founderPct'] ?? data['f'] ?? 20) as num).toDouble();
            _laborPct = ((data['laborPct'] ?? data['l'] ?? 20) as num).toDouble();
            _mainFundPct = ((data['mainFundPct'] ?? data['m'] ?? 60) as num).toDouble();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fundController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final fund = double.tryParse(_fundController.text.trim()) ?? 0.0;
    final founderPool = fund * (_founderPct / 100);
    final laborPool = fund * (_laborPct / 100);
    final mainPool = fund * (_mainFundPct / 100);

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
          Navigator.pop(context);
        } else if (state is TransactionFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            'এককালীন মুনাফা বণ্টন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: GradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available profit summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বণ্টনযোগ্য মোট পুঞ্জীভূত মুনাফা',
                          style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatAmount(widget.availableProfit),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  DualFieldRow(
                    left: CustomTextField(
                      label: 'বণ্টন করার মোট তহবিল',
                      controller: _fundController,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    right: CustomTextField(
                      label: 'বণ্টনের তারিখ',
                      controller: _dateController,
                      isRequired: true,
                      readOnly: true,
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: HugeIcons.strokeRoundedCalendar03,
                      onTap: () => DatePickerHelper.show(
                        context: context,
                        controller: _dateController,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mode Selector
                  Text(
                    'পরিশোধের মাধ্যম',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableChip(
                          label: 'নগদ ক্যাশ (Cash)',
                          icon: HugeIcons.strokeRoundedMoney03,
                          isSelected: _mode == 'cash',
                          onSelected: () => setState(() => _mode = 'cash'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableChip(
                          label: 'ব্যাংক হিসাব (Bank)',
                          icon: HugeIcons.strokeRoundedBank,
                          isSelected: _mode == 'bank',
                          onSelected: () => setState(() => _mode = 'bank'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'মন্তব্য / বর্ণনা',
                    controller: _noteController,
                    hintText: 'যেমন: ২০২৬ সালের ঈদুল ফিতর উপলক্ষ্যে বণ্টন',
                  ),
                  const SizedBox(height: 20),

                  // Distribution Pools Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বণ্টন নীতিমালা প্রিভিউ (Formula Breakdown)',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPoolRow('প্রতিষ্ঠাতা সদস্য পুল (${_founderPct.round()}%)', _formatAmount(founderPool), 'প্রতিষ্ঠাতাদের মাঝে সমবণ্টন'),
                        const Divider(height: 16),
                        _buildPoolRow('শ্রমদাতা সদস্য পুল (${_laborPct.round()}%)', _formatAmount(laborPool), 'শ্রমদাতাদের মাঝে সমবণ্টন'),
                        const Divider(height: 16),
                        _buildPoolRow('মূল শেয়ার তহবিল পুল (${_mainFundPct.round()}%)', _formatAmount(mainPool), 'শেয়ার সংখ্যা অনুপাতে বণ্টন'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SpringButton(
                    width: double.infinity,
                    onPressed: _confirmPayout,
                    child: Text(
                      'এক ক্লিকে বণ্টন কার্যকর করুন',
                      style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoolRow(String title, String amount, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(sub, style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ],
    );
  }

  void _confirmPayout() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fund = double.tryParse(_fundController.text.trim()) ?? 0.0;
    if (fund <= 0) {
      AppNotifier.showErrorSnackBar(context, 'সঠিক তহবিলের পরিমাণ দিন');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'মুনাফা বণ্টন নিশ্চিতকরণ',
        message: 'আপনি কি ${_formatAmount(fund)} টাকা সকল সদস্যের মাঝে বণ্টন করে প্রত্যেকের নামে ভাউচার তৈরি করতে চান?',
        confirmText: 'বণ্টন করুন',
        onConfirm: () {
          context.read<TransactionBloc>().add(
                BulkPayoutRequested(
                  totalFund: fund,
                  date: DateFormatter.yyyyMMdd(_dateController.text.trim()),
                  mode: _mode,
                  acct: '',
                  note: _noteController.text.trim(),
                ),
              );
          Navigator.pop(context);
        },
      ),
    );
  }
}
