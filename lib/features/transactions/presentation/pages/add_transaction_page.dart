import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_dropdown_field.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/core/utils/helpers/date_picker_helper.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/data/repos/bank_repo.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';

const String _noProjectLabel = 'প্রকল্প নির্দিষ্ট নয়';

class AddTransactionPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const AddTransactionPage());

  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final _vnoController = TextEditingController();
  final _dateController = TextEditingController();
  final _sectorController = TextEditingController();
  final _projectController = TextEditingController();
  final _memberController = TextEditingController();
  final _investProjectController = TextEditingController();
  final _donorController = TextEditingController();
  final _bankController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _dir = 'in'; // 'in' = আয়, 'out' = ব্যয়
  String _mode = 'cash';
  bool _isLoading = true;

  List<SectorModel> _incomeSectors = [];
  List<SectorModel> _expenseSectors = [];
  List<ProjectModel> _projects = [];
  List<MemberModel> _members = [];
  List<BankAccountModel> _banks = [];

  SectorModel? _sector;
  String _projectId = ''; // খাত = প্রকল্প
  String _memberNo = ''; // খাত = শেয়ারহোল্ডার
  String _investProjectId = ''; // আয় → শেয়ারহোল্ডার, ঐচ্ছিক প্রকল্প ট্যাগ
  String _bankId = ''; // মাধ্যম = ব্যাংক

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormatter.ddMMyyyy(DateTime.now());
    _initData();
  }

  Future<void> _initData() async {
    try {
      final nextVNo = await TransactionsRepo.getNextVoucherNo();
      final incomeSectors = await SetupRepo.getSectors(SectorType.income);
      final expenseSectors = await SetupRepo.getSectors(SectorType.expense);
      final projects = await SetupRepo.getProjects();
      final members = await MembersRepo.getMembers();
      List<BankAccountModel> banks = [];
      try {
        banks = await BankRepo.getBankAccounts();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _vnoController.text = nextVNo;
        _incomeSectors = incomeSectors;
        _expenseSectors = expenseSectors;
        _projects = projects;
        _members = members;
        _banks = banks.where((b) => b.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppNotifier.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  void dispose() {
    _vnoController.dispose();
    _dateController.dispose();
    _sectorController.dispose();
    _projectController.dispose();
    _memberController.dispose();
    _investProjectController.dispose();
    _donorController.dispose();
    _bankController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<SectorModel> get _activeSectors =>
      (_dir == 'in' ? _incomeSectors : _expenseSectors).where((s) => s.isActive).toList();

  bool get _isProjectSector => _sector?.key == SectorModel.keyProkolpo;
  bool get _isShareholderSector => _sector?.key == SectorModel.keyShareholder;
  bool get _isDonationSector => _sector?.key == SectorModel.keyDonation;

  void _resetEntity() {
    _projectId = '';
    _projectController.clear();
    _memberNo = '';
    _memberController.clear();
    _investProjectId = '';
    _investProjectController.clear();
    _donorController.clear();
  }

  void _setDir(String dir) {
    setState(() {
      _dir = dir;
      _sector = null;
      _sectorController.clear();
      _resetEntity();
    });
  }

  void _onSectorSelected(String name) {
    SectorModel? found;
    for (final s in _activeSectors) {
      if (s.name == name) {
        found = s;
        break;
      }
    }
    setState(() {
      _sector = found;
      _resetEntity();
    });
  }

  String _projectIdByName(String name) {
    for (final p in _projects) {
      if (p.name == name) return p.id;
    }
    return '';
  }

  String _memberNoFromLabel(String label) => label.split(' - ').first.trim();

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
            'নতুন ভাউচার তৈরি',
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
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DualFieldRow(
                          left: CustomTextField(
                            label: 'ভাউচার নম্বর',
                            controller: _vnoController,
                            isRequired: true,
                            readOnly: true,
                          ),
                          right: CustomTextField(
                            label: 'তারিখ',
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

                        // ১. আয় / ব্যয়
                        _sectionLabel('লেনদেনের ধরন'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableChip(
                                label: 'আয় (Income)',
                                showCheckmark: false,
                                isSelected: _dir == 'in',
                                onSelected: () => _setDir('in'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableChip(
                                label: 'ব্যয় (Expense)',
                                showCheckmark: false,
                                isSelected: _dir == 'out',
                                onSelected: () => _setDir('out'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ২. খাত
                        CustomDropdownField(
                          label: 'খাত',
                          controller: _sectorController,
                          isRequired: true,
                          isSearchable: true,
                          sheetTitle: _dir == 'in' ? 'আয়ের খাত নির্বাচন করুন' : 'ব্যয়ের খাত নির্বাচন করুন',
                          options: _activeSectors.map((s) => s.name).toList(),
                          onChanged: _onSectorSelected,
                        ),
                        const SizedBox(height: 16),

                        // ৩. খাত অনুযায়ী পরের ধাপ
                        if (_isProjectSector) ...[
                          CustomDropdownField(
                            label: 'প্রকল্প নির্বাচন করুন',
                            controller: _projectController,
                            isRequired: true,
                            isSearchable: true,
                            sheetTitle: 'প্রকল্প নির্বাচন করুন',
                            options: _projects.map((p) => p.name).toList(),
                            onChanged: (name) => setState(() => _projectId = _projectIdByName(name)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_isShareholderSector) ...[
                          CustomDropdownField(
                            label: 'সদস্য নির্বাচন করুন',
                            controller: _memberController,
                            isRequired: true,
                            isSearchable: true,
                            hintText: 'শেয়ারহোল্ডার নির্বাচন করুন',
                            sheetTitle: 'সদস্য নির্বাচন করুন',
                            options: _members.map((m) => '${m.no} - ${m.displayName}').toList(),
                            onChanged: (val) => setState(() => _memberNo = _memberNoFromLabel(val)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // আয় → শেয়ারহোল্ডার: বিনিয়োগ কোন প্রকল্পের জন্য (ঐচ্ছিক)
                        if (_isShareholderSector && _dir == 'in') ...[
                          CustomDropdownField(
                            label: 'সংশ্লিষ্ট প্রকল্প (ঐচ্ছিক)',
                            controller: _investProjectController,
                            isSearchable: true,
                            sheetTitle: 'প্রকল্প নির্বাচন করুন',
                            options: [_noProjectLabel, ..._projects.map((p) => p.name)],
                            onChanged: (name) => setState(
                              () => _investProjectId = name == _noProjectLabel ? '' : _projectIdByName(name),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_isDonationSector) ...[
                          CustomTextField(
                            label: 'ডোনেশন গ্রহীতা / বিবরণ (ঐচ্ছিক)',
                            controller: _donorController,
                            hintText: 'যেমন: বন্যা ত্রাণ',
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ৪. পরিশোধের মাধ্যম
                        _sectionLabel('পরিশোধের মাধ্যম (Payment Mode)'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableChip(
                                label: 'নগদ (Cash)',
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                fontSize: 12,
                                isSelected: _mode == 'cash',
                                onSelected: () => setState(() => _mode = 'cash'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableChip(
                                label: 'ব্যাংক (Bank)',
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                fontSize: 12,
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

                        // ৫. পরিমাণ, মন্তব্য
                        CustomTextField(
                          label: 'টাকার পরিমাণ (টাকা)',
                          controller: _amountController,
                          isRequired: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          hintText: 'যেমন: 5000',
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          label: 'বিবরণ ও মন্তব্য (Note)',
                          controller: _noteController,
                          hintText: 'লেনদেনের বিস্তারিত উদ্দেশ্য...',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        SpringButton(
                          width: double.infinity,
                          onPressed: _saveTransaction,
                          child: Text(
                            'ভাউচার সম্পন্ন করুন',
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.notoSansBengali(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  void _saveTransaction() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final sector = _sector;
    if (sector == null) {
      AppNotifier.showErrorSnackBar(context, 'খাত নির্বাচন করুন');
      return;
    }
    if (_isProjectSector && _projectId.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'প্রকল্প নির্বাচন করুন');
      return;
    }
    if (_isShareholderSector && _memberNo.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'সদস্য নির্বাচন করুন');
      return;
    }
    if (_mode == 'bank' && _bankId.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'ব্যাংক হিসাব নির্বাচন করুন');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppNotifier.showErrorSnackBar(context, 'সঠিক টাকার পরিমাণ দিন');
      return;
    }

    String project = '';
    if (_isProjectSector) project = _projectId;
    if (_isShareholderSector && _dir == 'in') project = _investProjectId;

    String acct = '';
    if (_mode == 'bank') acct = _bankId;

    var note = _noteController.text.trim();
    if (_isDonationSector && _donorController.text.trim().isNotEmpty) {
      final donor = 'গ্রহীতা: ${_donorController.text.trim()}';
      note = note.isEmpty ? donor : '$donor | $note';
    }

    final trx = TransactionModel(
      id: '',
      vno: _vnoController.text.trim(),
      date: DateFormatter.yyyyMMdd(_dateController.text.trim()),
      dir: _dir,
      sectorId: sector.id,
      sectorKey: sector.key,
      sectorName: sector.name,
      project: project,
      member: _isShareholderSector ? _memberNo : '',
      kind: '', // manual voucher, never the profit formula
      mode: _mode,
      acct: acct,
      amount: amount,
      note: note,
    );

    context.read<TransactionBloc>().add(TransactionAddRequested(trx));
  }
}
