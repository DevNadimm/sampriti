import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_dropdown_field.dart';
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
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/data/repos/bank_repo.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';

class ProjectProfitDistributionPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const ProjectProfitDistributionPage());

  const ProjectProfitDistributionPage({super.key});

  @override
  State<ProjectProfitDistributionPage> createState() => _ProjectProfitDistributionPageState();
}

class _ProjectProfitDistributionPageState extends State<ProjectProfitDistributionPage> {
  final _formKey = GlobalKey<FormState>();
  final _projectController = TextEditingController();
  final _fundController = TextEditingController();
  final _dateController = TextEditingController(text: DateFormatter.ddMMyyyy(DateTime.now()));
  final _noteController = TextEditingController(text: 'মুনাফা বণ্টন');
  final _bankController = TextEditingController();

  List<ProjectModel> _projects = [];
  ProjectModel? _project;
  String _mode = 'cash';
  List<BankAccountModel> _banks = [];
  String _bankId = ''; // selected bank account id, used when _mode == 'bank'
  ProjectPayoutPreview? _preview;
  String? _previewError;
  bool _loadingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _projectController.dispose();
    _fundController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final list = await SetupRepo.getProjects();
      if (mounted) setState(() => _projects = list);
    } catch (e) {
      if (mounted) setState(() => _previewError = e.toString());
    }
    try {
      final banks = await BankRepo.getBankAccounts();
      if (mounted) setState(() => _banks = banks.where((b) => b.isActive).toList());
    } catch (_) {}
  }

  ProjectModel? _findProject(String name) {
    for (final p in _projects) {
      if (p.name == name) return p;
    }
    return null;
  }

  double get _fund => double.tryParse(_fundController.text.trim()) ?? 0.0;

  Future<void> _onProjectSelected(String name) async {
    final p = _findProject(name);
    setState(() {
      _project = p;
      _preview = null;
      _previewError = null;
    });
    if (p == null) return;

    // Prefill with project's net profit (income minus expense)
    try {
      final net = await TransactionsRepo.getProjectNetProfit(p.id);
      if (!mounted) return;
      if (net > 0) _fundController.text = net.round().toString();
    } catch (_) {}

    await _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    final p = _project;
    final fund = _fund;
    if (p == null || fund <= 0) {
      if (mounted) setState(() {
        _preview = null;
        _previewError = null;
      });
      return;
    }

    if (mounted) setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final pv = await TransactionsRepo.previewProjectDistribution(projectId: p.id, totalProfit: fund);
      if (mounted) setState(() {
        _preview = pv;
        _loadingPreview = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _preview = null;
        _previewError = e.toString();
        _loadingPreview = false;
      });
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
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
            'প্রকল্পভিত্তিক মুনাফা বণ্টন',
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
                  CustomDropdownField(
                    label: 'প্রকল্প',
                    controller: _projectController,
                    options: _projects.map((p) => p.name).toList(),
                    isRequired: true,
                    isSearchable: true,
                    sheetTitle: 'প্রকল্প নির্বাচন করুন',
                    onChanged: _onProjectSelected,
                  ),
                  const SizedBox(height: 16),

                  DualFieldRow(
                    left: CustomTextField(
                      label: 'বণ্টন করার মুনাফা (টাকা)',
                      controller: _fundController,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _refreshPreview(),
                    ),
                    right: CustomTextField(
                      label: 'বণ্টনের তারিখ',
                      controller: _dateController,
                      isRequired: true,
                      readOnly: true,
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: HugeIcons.strokeRoundedCalendar03,
                      onTap: () => DatePickerHelper.show(context: context, controller: _dateController),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  if (_mode == 'bank') ...[
                    CustomDropdownField(
                      label: 'ব্যাংক হিসাব নির্বাচন করুন',
                      controller: _bankController,
                      isRequired: true,
                      isSearchable: true,
                      sheetTitle: 'ব্যাংক হিসাব নির্বাচন করুন',
                      options: _banks.map((b) => b.displayName).toList(),
                      onChanged: (name) {
                        for (final b in _banks) {
                          if (b.displayName == name) {
                            setState(() => _bankId = b.id);
                            break;
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomTextField(
                    label: 'মন্তব্য / বর্ণনা',
                    controller: _noteController,
                  ),
                  const SizedBox(height: 20),

                  _buildPreviewCard(),
                  const SizedBox(height: 24),

                  SpringButton(
                    width: double.infinity,
                    onPressed: _preview == null ? null : _confirmPayout,
                    child: Text(
                      'মুনাফা বণ্টন কার্যকর করুন',
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

  Widget _buildPreviewCard() {
    if (_loadingPreview) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (_previewError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error),
        ),
        child: Text(
          _previewError!,
          style: GoogleFonts.notoSansBengali(fontSize: 13, color: AppColors.error),
        ),
      );
    }
    final pv = _preview;
    if (pv == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          _project == null ? 'প্রথমে প্রকল্প নির্বাচন করুন' : 'মুনাফার পরিমাণ দিন',
          style: GoogleFonts.notoSansBengali(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    final basisLabel = pv.usesInvestmentBasis ? 'বিনিয়োগ' : 'শেয়ার';

    return Container(
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
            'বণ্টন নীতিমালা প্রিভিউ',
            style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          _buildPoolRow('প্রতিষ্ঠাতা সদস্য পুল (২০%)', _formatAmount(pv.founderPool),
              pv.founderPoolOrphan ? 'এই প্রকল্পে কোনো প্রতিষ্ঠাতা নেই — অবণ্টিত থাকবে' : 'প্রতিষ্ঠাতাদের মাঝে সমবণ্টন'),
          const Divider(height: 16),
          _buildPoolRow('শ্রমদাতা সদস্য পুল (২০%)', _formatAmount(pv.laborPool),
              pv.laborPoolOrphan ? 'এই প্রকল্পে কোনো শ্রমদাতা নেই — অবণ্টিত থাকবে' : 'শ্রমদাতাদের মাঝে সমবণ্টন'),
          const Divider(height: 16),
          _buildPoolRow('মূল শেয়ার তহবিল পুল (৬০%)', _formatAmount(pv.mainPool),
              '$basisLabel অনুপাতে বণ্টন'),
          const Divider(height: 16),
          Text(
            'সদস্যভিত্তিক বণ্টন',
            style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final r in pv.rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${r.member.no} · ${r.member.displayName}'
                      '${r.member.founder ? ' · প্রতিষ্ঠাতা' : ''}'
                      '${r.member.labor ? ' · শ্রমদাতা' : ''}\n'
                      '$basisLabel: ${r.basis.round()}',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    _formatAmount(r.amount),
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('মোট বণ্টন', style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(
                _formatAmount(pv.totalDistributed),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoolRow(String title, String amount, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(sub, style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
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
    final pv = _preview;
    if (pv == null) return;

    final fund = _fund;
    if (fund <= 0) {
      AppNotifier.showErrorSnackBar(context, 'সঠিক মুনাফার পরিমাণ দিন');
      return;
    }

    // Bank mode must name the exact account, otherwise the balance calculation
    // cannot tell which bank to deduct from.
    if (_mode == 'bank' && _bankId.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'ব্যাংক হিসাব নির্বাচন করুন');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'মুনাফা বণ্টন নিশ্চিতকরণ',
        message: '${pv.project.name} প্রকল্পের ${_formatAmount(fund)} মুনাফা '
            '${pv.rows.length} জন সদস্যের মধ্যে বণ্টন করে ভাউচার তৈরি করতে চান?',
        confirmText: 'বণ্টন করুন',
        onConfirm: () {
          context.read<TransactionBloc>().add(
                ProjectProfitDistributionRequested(
                  projectId: pv.project.id,
                  totalProfit: fund,
                  date: DateFormatter.yyyyMMdd(_dateController.text.trim()),
                  mode: _mode,
                  acct: _mode == 'bank' ? _bankId : '',
                  note: _noteController.text.trim(),
                ),
              );
          Navigator.pop(context);
        },
      ),
    );
  }
}
