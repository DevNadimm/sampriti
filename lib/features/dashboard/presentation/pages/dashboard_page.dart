import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/app_developer_footer.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/app_review_service.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/auth/data/models/user_session_model.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/dashboard_stat_tile.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/quick_actions_section.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/section_header.dart';
import 'package:sampriti/features/dashboard/presentation/widgets/unified_financial_card.dart';
import 'package:sampriti/features/documents/presentation/pages/share_certificate_page.dart';
import 'package:sampriti/features/documents/presentation/pages/shareholder_doc_page.dart';
import 'package:sampriti/features/finance/presentation/pages/bank_accounts_page.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/members/presentation/pages/member_details_page.dart';
import 'package:sampriti/features/members/presentation/pages/members_page.dart';
import 'package:sampriti/features/reports/presentation/pages/reports_page.dart';
import 'package:sampriti/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:sampriti/features/transactions/presentation/pages/bulk_payout_page.dart';
import 'package:sampriti/features/transactions/presentation/pages/transactions_page.dart';

class DashboardPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const DashboardPage());

  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  MemberModel? _currentMember;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardFetchRequested());
    _loadMemberProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppReviewService.recordActionAndPromptIfNeeded(context);
      }
    });
  }

  Future<void> _loadMemberProfile() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && !authState.session.isAdmin) {
      final mNo = authState.session.memberNo;
      if (mNo != null && mNo.isNotEmpty) {
        final m = await MembersRepo.getMemberByNo(mNo);
        if (mounted && m != null) {
          setState(() {
            _currentMember = m;
          });
        }
      }
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState is AuthAuthenticated ? authState.session : null;
        final isAdmin = session?.isAdmin ?? true;
        final title = isAdmin ? 'অ্যাডমিন' : (session?.name ?? 'শেয়ারহোল্ডার');
        final subtitle = isAdmin ? 'ম্যানেজার' : 'শেয়ার নং: ${session?.memberNo ?? "—"}';

        return Scaffold(
          appBar: DashboardAppBar(
            title: title,
            subtitle: subtitle,
            isAdmin: isAdmin,
            photoUrl: _currentMember?.photo ?? session?.photoUrl,
            memberNo: session?.memberNo,
            onAvatarTap: () {
              if (!isAdmin && session?.memberNo != null) {
                Navigator.push(
                  context,
                  MemberDetailsPage.route(memberNo: session!.memberNo!),
                ).then((_) => _loadMemberProfile());
              }
            },
          ),
          body: GradientBackground(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading || state is DashboardInitial) {
                  return const DashboardSkeleton();
                }

                if (state is DashboardFailure) {
                  return ErrorStateWidget(
                    message: state.message,
                    onRetry: () => context.read<DashboardBloc>().add(DashboardFetchRequested()),
                  );
                }

                if (state is DashboardLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<DashboardBloc>().add(DashboardFetchRequested());
                      await _loadMemberProfile();
                    },
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Unified Financial Card (Segmented Animated Toggle from rent_book)
                          UnifiedFinancialCard(
                            summary: state.summary,
                            isShareholder: !isAdmin,
                          ),
                          const SizedBox(height: 20),

                          // 2. Section Header: Quick Actions
                          const SectionHeader(title: 'কুইক অ্যাকশন (Quick Actions)'),
                          const SizedBox(height: 10),

                          // 3. Quick Actions Grid (4 columns, rounded cards from rent_book)
                          QuickActionsSection(
                            isAdmin: isAdmin,
                            items: _buildQuickActions(context, isAdmin, session, state.summary),
                          ),
                          const SizedBox(height: 24),

                          // 4. Section Header: Stats & Summary
                          const SectionHeader(title: 'সারসংক্ষেপ ও পরিসংখ্যান'),
                          const SizedBox(height: 10),

                          // 5. Secondary Stat Cards (DashboardStatTile from rent_book)
                          _buildStatTiles(state.summary, isAdmin),
                          const SizedBox(height: 24),

                          // 6. Recent Transactions Section (CustomContainer from rent_book)
                          RecentTransactionsSection(
                            transactions: state.summary.recentTransactions,
                            onSeeAll: () {
                              Navigator.push(
                                context,
                                TransactionsPage.route(memberNo: isAdmin ? null : session?.memberNo),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const AppDeveloperFooter(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }

  List<QuickActionItem> _buildQuickActions(
    BuildContext context,
    bool isAdmin,
    UserSessionModel? session,
    DashboardSummaryModel summary,
  ) {
    if (isAdmin) {
      return [
        QuickActionItem(
          icon: HugeIcons.strokeRoundedUserGroup,
          label: 'সদস্যরা',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(context, MembersPage.route()).then((_) {
              if (context.mounted) {
                context.read<DashboardBloc>().add(DashboardFetchRequested());
              }
            });
          },
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedInvoice02,
          label: 'নতুন ভাউচার',
          color: AppColors.accent,
          onTap: () {
            Navigator.push(context, AddTransactionPage.route()).then((_) {
              if (context.mounted) {
                context.read<DashboardBloc>().add(DashboardFetchRequested());
                AppReviewService.recordActionAndPromptIfNeeded(context);
              }
            });
          },
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedTransaction,
          label: 'লেনদেন তালিকা',
          color: AppColors.success,
          onTap: () => Navigator.push(context, TransactionsPage.route()),
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedCoins01,
          label: 'মুনাফা বণ্টন',
          color: AppColors.accentYellow,
          onTap: () {
            Navigator.push(
              context,
              BulkPayoutPage.route(availableProfit: summary.distributableProfit),
            ).then((_) {
              if (context.mounted) {
                context.read<DashboardBloc>().add(DashboardFetchRequested());
              }
            });
          },
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedBank,
          label: 'ব্যাংক হিসাব',
          color: AppColors.primaryDark,
          onTap: () => Navigator.push(context, BankAccountsPage.route()),
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedAnalytics02,
          label: 'আর্থিক রিপোর্ট',
          color: AppColors.blue,
          onTap: () => Navigator.push(context, ReportsPage.route()),
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedShare01,
          label: 'অ্যাপ শেয়ার',
          color: AppColors.primary,
          onTap: () => AppReviewService.shareApp(),
        ),
        QuickActionItem(
          icon: HugeIcons.strokeRoundedStar,
          label: 'রেটিং দিন',
          color: AppColors.accentYellow,
          onTap: () => AppReviewService.showManualRatingDialog(context),
        ),
      ];
    }

    // Shareholder Quick Actions
    final memberNo = session?.memberNo ?? '';
    return [
      QuickActionItem(
        icon: HugeIcons.strokeRoundedUserSquare,
        label: 'আমার প্রোফাইল',
        color: AppColors.primary,
        onTap: () {
          if (memberNo.isNotEmpty) {
            Navigator.push(context, MemberDetailsPage.route(memberNo: memberNo));
          }
        },
      ),
      QuickActionItem(
        icon: HugeIcons.strokeRoundedDiploma,
        label: 'সার্টিফিকেট',
        color: AppColors.accent,
        onTap: () {
          if (memberNo.isNotEmpty) {
            Navigator.push(context, ShareCertificatePage.route(memberNo: memberNo));
          }
        },
      ),
      QuickActionItem(
        icon: HugeIcons.strokeRoundedReceiptDollar,
        label: 'আমার ভাউচার',
        color: AppColors.success,
        onTap: () {
          Navigator.push(context, TransactionsPage.route(memberNo: memberNo));
        },
      ),
      QuickActionItem(
        icon: HugeIcons.strokeRoundedFile02,
        label: 'শেয়ার ফরম',
        color: AppColors.accentYellow,
        onTap: () {
          if (memberNo.isNotEmpty) {
            Navigator.push(context, ShareholderDocPage.route(memberNo: memberNo));
          }
        },
      ),
      QuickActionItem(
        icon: HugeIcons.strokeRoundedShare01,
        label: 'অ্যাপ শেয়ার',
        color: AppColors.primary,
        onTap: () => AppReviewService.shareApp(),
      ),
      QuickActionItem(
        icon: HugeIcons.strokeRoundedStar,
        label: 'রেটিং দিন',
        color: AppColors.accentYellow,
        onTap: () => AppReviewService.showManualRatingDialog(context),
      ),
    ];
  }

  Widget _buildStatTiles(DashboardSummaryModel summary, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 67,
            child: Row(
              children: [
                DashboardStatTile(
                  icon: isAdmin ? HugeIcons.strokeRoundedBank : HugeIcons.strokeRoundedCoins01,
                  value: isAdmin ? _formatAmount(summary.bankBalance) : '${summary.myShares} টি',
                  label: isAdmin ? 'ব্যাংক ব্যালেন্স' : 'আমার শেয়ার সংখ্যা',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                DashboardStatTile(
                  icon: isAdmin ? HugeIcons.strokeRoundedMoney03 : HugeIcons.strokeRoundedCoins02,
                  value: isAdmin ? _formatAmount(summary.cashBalance) : _formatAmount(summary.myProfitDue),
                  label: isAdmin ? 'ক্যাশ ইন হ্যান্ড' : 'প্রাপ্য মোট মুনাফা',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 67,
            child: Row(
              children: [
                DashboardStatTile(
                  icon: isAdmin ? HugeIcons.strokeRoundedBuilding03 : HugeIcons.strokeRoundedCheckmarkCircle02,
                  value: isAdmin ? _formatAmount(summary.institutionInvestment) : _formatAmount(summary.myProfitPaid),
                  label: isAdmin ? 'প্রতিষ্ঠানে বিনিয়োগ' : 'প্রাপ্ত মুনাফা',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                DashboardStatTile(
                  icon: HugeIcons.strokeRoundedTime02,
                  value: isAdmin ? _formatAmount(summary.pendingPayout) : _formatAmount(summary.myProfitRemaining),
                  label: isAdmin ? 'বকেয়া লভ্যাংশ' : 'বকেয়া মুনাফা',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
