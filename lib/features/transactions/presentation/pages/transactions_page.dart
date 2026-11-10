import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/core/utils/helpers/option_picker_bottom_sheet_helper.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:sampriti/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:sampriti/features/transactions/presentation/pages/voucher_details_page.dart';

class TransactionsPage extends StatefulWidget {
  final String? memberNo;
  final String? type;

  static Route route({String? memberNo, String? type}) => MaterialPageRoute(
        builder: (_) => TransactionsPage(memberNo: memberNo, type: type),
      );

  const TransactionsPage({super.key, this.memberNo, this.type});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedType = 'all';

  final List<Map<String, String>> _typeFilters = [
    {'key': 'all', 'label': 'সকল লেনদেন'},
    {'key': 'share_in', 'label': 'শেয়ার বিনিয়োগ'},
    {'key': 'payout', 'label': 'মুনাফা বণ্টন'},
    {'key': 'inst_invest', 'label': 'প্রতিষ্ঠানে বিনিয়োগ'},
    {'key': 'inst_income', 'label': 'প্রতিষ্ঠানের আয়'},
    {'key': 'donation', 'label': 'ডোনেশন'},
    {'key': 'expense', 'label': 'ব্যয়/খরচ'},
    {'key': 'bank_dep', 'label': 'ব্যাংক জমা'},
    {'key': 'bank_wd', 'label': 'ব্যাংক উত্তোলন'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type ?? 'all';
    _fetch();
  }

  void _fetch() {
    context.read<TransactionBloc>().add(
          TransactionFetchRequested(
            memberNo: widget.memberNo,
            type: _selectedType == 'all' ? null : _selectedType,
          ),
        );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthBloc>().state is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).session.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          widget.memberNo != null ? 'লেনদেন বিবরণ (${widget.memberNo})' : 'লেনদেন ও ভাউচার',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedFilter,
              size: 20,
              color: AppColors.primary,
            ),
            tooltip: 'ফিল্টার করুন',
            onPressed: () {
              final currentLabel = _typeFilters.firstWhere(
                (f) => f['key'] == _selectedType,
                orElse: () => _typeFilters.first,
              )['label']!;
              final controller = TextEditingController(text: currentLabel);
              OptionPickerBottomSheetHelper.show(
                context: context,
                title: 'লেনদেনের ধরন ফিল্টার',
                options: _typeFilters.map((f) => f['label']!).toList(),
                controller: controller,
                onSelect: (selectedLabel) {
                  final match = _typeFilters.firstWhere((f) => f['label'] == selectedLabel);
                  setState(() => _selectedType = match['key']!);
                  _fetch();
                },
              );
            },
          ),
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is! TransactionLoaded || state.transactions.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPrinter,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'লেজার PDF ডাউনলোড',
                onPressed: () {
                  Navigator.push(
                    context,
                    PdfPreviewPage.route(
                      title: widget.memberNo != null ? 'লেনদেন খতিয়ান (${widget.memberNo})' : 'লেনদেন খতিয়ান (লেজার)',
                      pdfFileName: 'sampriti-ledger${widget.memberNo != null ? '-${widget.memberNo}' : ''}.pdf',
                      buildPdf: () => PdfDocumentService.generateLedgerPdf(
                        state.transactions,
                        title: widget.memberNo != null ? 'লেনদেন খতিয়ান (${widget.memberNo})' : 'লেনদেন খতিয়ান ও লেজার বিবরণী',
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedInvoice02,
                size: 22,
                color: AppColors.primary,
              ),
              onPressed: () {
                Navigator.push(context, AddTransactionPage.route()).then((_) => _fetch());
              },
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Horizontal Filter Chips
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _typeFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _typeFilters[index];
                  final isSelected = _selectedType == f['key'];
                  return SelectableChip(
                    label: f['label']!,
                    isSelected: isSelected,
                    height: 38,
                    showCheckmark: isSelected,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onSelected: () {
                      setState(() => _selectedType = f['key']!);
                      _fetch();
                    },
                  );
                },
              ),
            ),

            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading || state is TransactionInitial) {
                    return const Center(child: Loader());
                  }

                  if (state is TransactionFailure) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: _fetch,
                    );
                  }

                  if (state is TransactionLoaded) {
                    final txs = state.transactions;

                    if (txs.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'কোনো লেনদেন পাওয়া যায়নি',
                        message: 'এই ফিল্টারের অধীনে কোনো ভাউচার রেকর্ড করা নেই।',
                      );
                    }

                    final totalAmount = txs.fold<double>(0, (sum, t) => sum + t.amount);

                    return Column(
                      children: [
                        // Total Count & Amount Banner
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'মোট ভাউচার: ${txs.length} টি',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'মোট অঙ্ক: ${_formatAmount(totalAmount)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => _fetch(),
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: txs.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final trx = txs[index];
                                return _buildTransactionCard(context, trx);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedInvoice02, size: 20, color: AppColors.white),
              label: Text(
                'নতুন ভাউচার',
                style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.push(context, AddTransactionPage.route()).then((_) => _fetch());
              },
            )
          : null,
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel trx) {
    final isPositive = trx.isInflow;
    final color = isPositive
        ? AppColors.success
        : (trx.isOutflow ? AppColors.error : AppColors.accent);

    return InkWell(
      onTap: () {
        Navigator.push(context, VoucherDetailsPage.route(transaction: trx)).then((_) => _fetch());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: isPositive
                      ? HugeIcons.strokeRoundedArrowDownLeft01
                      : HugeIcons.strokeRoundedArrowUpRight01,
                  size: 22,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trx.typeTitle,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          trx.vno,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trx.uiDate,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (trx.member.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${trx.member}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${isPositive ? "+" : (trx.isOutflow ? "-" : "")}${_formatAmount(trx.amount)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
