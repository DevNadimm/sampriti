import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/shimmer/shimmer_list.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/presentation/bloc/bank_bloc.dart';
import 'package:sampriti/features/finance/presentation/widgets/cash_card.dart';
import 'package:sampriti/features/finance/presentation/pages/add_edit_bank_account_page.dart';
import 'package:sampriti/features/finance/presentation/pages/bank_transfer_page.dart';
import 'package:sampriti/features/finance/presentation/widgets/bank_card.dart';

class BankAccountsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const BankAccountsPage());

  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BankBloc>().add(BankFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  void _onAddAccount() {
    Navigator.push(context, AddEditBankAccountPage.route());
  }

  bool _isAdmin() {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated && s.session.isAdmin;
  }

  Future<void> _onEditCashOpening(double current) async {
    final controller = TextEditingController(text: current.round().toString());
    final bloc = context.read<BankBloc>();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'নগদের প্রারম্ভিক স্থিতি',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'যেমন: 50000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    bloc.add(BankCashOpeningSaveRequested(result));
  }

  void _onEditAccount(BankAccountModel account) {
    Navigator.push(context, AddEditBankAccountPage.route(account: account));
  }

  void _onDeleteAccount(BankAccountModel account) {
    AppConfirmationDialog.show(
      context,
      title: 'ব্যাংক হিসাব মুছে ফেলুন',
      message: 'আপনি কি নিশ্চিত যে "${account.displayName}" হিসাবটি মুছে ফেলতে চান?',
      confirmText: 'মুছে ফেলুন',
      isDestructive: true,
      onConfirm: () {
        context.read<BankBloc>().add(BankDeleteRequested(account.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BankBloc, BankState>(
      listener: (context, state) {
        if (state is BankActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
        } else if (state is BankFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            'ব্যাংক হিসাবসমূহ',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAddCircleHalfDot,
                size: 22,
                color: AppColors.primary,
              ),
              tooltip: 'নতুন ব্যাংক যুক্ত করুন',
              onPressed: _onAddAccount,
            ),
          ],
        ),
        body: GradientBackground(
          child: Column(
            children: [
              // Top Balance Overview Banner (RentBook Navy Gradient Card)
              BlocBuilder<BankBloc, BankState>(
                builder: (context, state) {
                  double totalBank = 0.0;
                  double cashBal = 0.0;
                  if (state is BankLoaded) {
                    totalBank = state.totalBankBalance;
                    cashBal = state.cashBalance;
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ব্যাংক সমূহের মোট সঞ্চয় স্থিতি',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(totalBank),
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentYellow,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'ক্যাশ ইন হ্যান্ড',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 11,
                                        color: AppColors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    Text(
                                      _formatAmount(cashBal),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quick Transfer Actions Row
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    BankTransferPage.route(isDeposit: true),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.white.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const HugeIcon(
                                          icon: HugeIcons.strokeRoundedArrowDownLeft01,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ব্যাংকে জমা',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    BankTransferPage.route(isDeposit: false),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.white.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const HugeIcon(
                                          icon: HugeIcons.strokeRoundedArrowUpRight01,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ব্যাংক উত্তোলন',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Search Bar (RentBook Style)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: CustomTextField.search(
                  controller: _searchController,
                  hintText: 'ব্যাংক হিসাব খুঁজুন (নাম, শাখা বা হিসাব নং)...',
                  onChanged: (val) {
                    context.read<BankBloc>().add(BankSearchRequested(val));
                  },
                ),
              ),

              // Cash in hand card (admin can edit the opening balance)
              BlocBuilder<BankBloc, BankState>(
                builder: (context, state) {
                  if (state is! BankLoaded) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: CashCard(
                      opening: state.cashOpening,
                      inflow: state.cashIn,
                      outflow: state.cashOut,
                      balance: state.cashBalance,
                      onEdit: _isAdmin() ? () => _onEditCashOpening(state.cashOpening) : null,
                    ),
                  );
                },
              ),

              // Bank Accounts List
              Expanded(
                child: BlocBuilder<BankBloc, BankState>(
                  builder: (context, state) {
                    if (state is BankLoading || state is BankInitial) {
                      return const ShimmerList(
                        itemCount: 4,
                        itemHeight: 140,
                      );
                    }

                    if (state is BankFailure && state is! BankLoaded) {
                      return ErrorStateWidget(
                        message: state.message,
                        onRetry: () => context.read<BankBloc>().add(BankFetchRequested()),
                      );
                    }

                    if (state is BankLoaded) {
                      final accounts = state.filteredAccounts;

                      if (accounts.isEmpty) {
                        return const Center(
                          child: EmptyStateWidget(
                            title: 'কোন ব্যাংক হিসাব নেই',
                            message: 'এখনো কোনো ব্যাংক হিসাব যুক্ত করা হয়নি',
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<BankBloc>().add(BankFetchRequested());
                        },
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final acc = accounts[index];
                            return BankCard(
                              account: acc,
                              onEdit: () => _onEditAccount(acc),
                              onDelete: () => _onDeleteAccount(acc),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onAddAccount,
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedAddCircleHalfDot,
            size: 20,
            color: AppColors.white,
          ),
          label: Text(
            'ব্যাংক যোগ করুন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
