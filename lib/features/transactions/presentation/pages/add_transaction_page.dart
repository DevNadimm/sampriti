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
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';

class AddTransactionPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const AddTransactionPage());

  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _vnoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final TextEditingController _instController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _acctController = TextEditingController();

  String _type = 'share_in';
  String _mode = 'cash';
  String _selectedMember = '';
  List<MemberModel> _members = [];
  List<String> _institutions = [];
  bool _isLoadingMembers = true;

  final List<Map<String, String>> _types = [
    {'key': 'share_in', 'title': 'সদস্যের বিনিয়োগ জমা'},
    {'key': 'inst_income', 'title': 'প্রতিষ্ঠানের আয় জমা'},
    {'key': 'donation', 'title': 'সদস্য ডোনেশন'},
    {'key': 'loan_return', 'title': 'লোন ফেরত প্রাপ্তি'},
    {'key': 'plan_dep', 'title': 'প্রকল্পে কিস্তি জমা'},
    {'key': 'inst_invest', 'title': 'প্রতিষ্ঠানে বিনিয়োগ'},
    {'key': 'inst_loan', 'title': 'প্রতিষ্ঠানকে লোন প্রদান'},
    {'key': 'inst_subsidy', 'title': 'ভর্তুকি প্রদান'},
    {'key': 'eid_bonus', 'title': 'ঈদ বোনাস প্রদান'},
    {'key': 'payout', 'title': 'মুনাফা বণ্টন প্রদান'},
    {'key': 'expense', 'title': 'অন্যান্য সাধারণ ব্যয়'},
    {'key': 'bank_dep', 'title': 'নগদ থেকে ব্যাংকে জমা'},
    {'key': 'bank_wd', 'title': 'ব্যাংক থেকে নগদ উত্তোলন'},
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormatter.ddMMyyyy(DateTime.now());
    _typeController.text = _types.firstWhere((t) => t['key'] == _type)['title']!;
    _initData();
  }

  Future<void> _initData() async {
    final nextVNo = await TransactionsRepo.getNextVoucherNo();
    final members = await MembersRepo.getMembers();
    final instList = await TransactionsRepo.getInstitutions();

    if (mounted) {
      setState(() {
        _vnoController.text = nextVNo;
        _members = members;
        _institutions = instList;
        if (members.isNotEmpty) {
          _selectedMember = members.first.no;
          _memberController.text = '${members.first.no} - ${members.first.displayName}';
        }
        if (instList.isNotEmpty) {
          _instController.text = instList.first;
        }
        _isLoadingMembers = false;
      });
    }
  }

  @override
  void dispose() {
    _vnoController.dispose();
    _dateController.dispose();
    _typeController.dispose();
    _memberController.dispose();
    _instController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _acctController.dispose();
    super.dispose();
  }

  bool get _needsMember => ['share_in', 'donation', 'payout', 'plan_dep'].contains(_type);

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
          child: _isLoadingMembers
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

                        // Transaction Type Dropdown via OptionPickerBottomSheetHelper
                        CustomDropdownField(
                          label: 'লেনদেনের ধরন',
                          controller: _typeController,
                          isRequired: true,
                          prefixIcon: HugeIcons.strokeRoundedInvoice02,
                          sheetTitle: 'লেনদেনের ধরন নির্বাচন করুন',
                          options: _types.map((t) => t['title']!).toList(),
                          onChanged: (selectedTitle) {
                            final match = _types.firstWhere((t) => t['title'] == selectedTitle);
                            setState(() {
                              _type = match['key']!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Member Picker via Searchable OptionPickerBottomSheetHelper
                        if (_needsMember) ...[
                          CustomDropdownField(
                            label: 'সদস্য নির্বাচন করুন',
                            controller: _memberController,
                            isRequired: true,
                            isSearchable: true,
                            hintText: 'শেয়ারহোল্ডার নির্বাচন করুন',
                            prefixIcon: HugeIcons.strokeRoundedUser,
                            sheetTitle: 'সদস্য নির্বাচন করুন',
                            options: _members.map((m) => '${m.no} - ${m.displayName}').toList(),
                            onChanged: (val) {
                              final memberNo = val.split(' - ').first.trim();
                              setState(() {
                                _selectedMember = memberNo;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Payment Mode Selector (Cash / Bank / Inst)
                        Text(
                          'পরিশোধের মাধ্যম (Payment Mode)',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableChip(
                                label: 'নগদ (Cash)',
                                icon: HugeIcons.strokeRoundedMoney03,
                                isSelected: _mode == 'cash',
                                onSelected: () => setState(() => _mode = 'cash'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableChip(
                                label: 'ব্যাংক (Bank)',
                                icon: HugeIcons.strokeRoundedBank,
                                isSelected: _mode == 'bank',
                                onSelected: () => setState(() => _mode = 'bank'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableChip(
                                label: 'প্রতিষ্ঠান (Inst)',
                                icon: HugeIcons.strokeRoundedBuilding03,
                                isSelected: _mode == 'inst',
                                onSelected: () => setState(() => _mode = 'inst'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_mode == 'bank') ...[
                          CustomTextField(
                            label: 'ব্যাংক হিসাব নম্বর / শাখা',
                            controller: _acctController,
                            hintText: 'যেমন: হিসাব নং ০১০০... / ইসলামী ব্যাংক',
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_mode == 'inst') ...[
                          CustomDropdownField(
                            label: 'প্রতিষ্ঠান নির্বাচন করুন',
                            controller: _instController,
                            isRequired: true,
                            isSearchable: true,
                            hintText: 'প্রতিষ্ঠান নির্বাচন করুন',
                            prefixIcon: HugeIcons.strokeRoundedBuilding03,
                            sheetTitle: 'প্রতিষ্ঠান নির্বাচন করুন',
                            options: _institutions,
                            onChanged: (val) {
                              _acctController.text = val;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        CustomTextField(
                          label: 'টাকার পরিমাণ (টাকা)',
                          controller: _amountController,
                          isRequired: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          hintText: 'যেমন: 5000',
                          prefixIcon: HugeIcons.strokeRoundedMoney03,
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

  void _saveTransaction() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppNotifier.showErrorSnackBar(context, 'সঠিক টাকার পরিমাণ দিন');
      return;
    }

    final trx = TransactionModel(
      id: '',
      vno: _vnoController.text.trim(),
      date: DateFormatter.yyyyMMdd(_dateController.text.trim()),
      type: _type,
      member: _needsMember ? _selectedMember : '',
      mode: _mode,
      acct: _mode == 'inst' && _acctController.text.trim().isEmpty
          ? _instController.text.trim()
          : _acctController.text.trim(),
      amount: amount,
      note: _noteController.text.trim(),
    );

    context.read<TransactionBloc>().add(TransactionAddRequested(trx));
  }
}
