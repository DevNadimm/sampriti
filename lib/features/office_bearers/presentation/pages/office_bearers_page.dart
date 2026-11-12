import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/office_bearers/data/models/office_bearer_model.dart';
import 'package:sampriti/features/office_bearers/data/repos/office_bearer_repo.dart';
import 'package:sampriti/features/office_bearers/presentation/pages/add_edit_office_bearer_page.dart';

/// Key used for bearers whose term has no readable year.
const int _undatedKey = -1;

class OfficeBearersPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const OfficeBearersPage());

  const OfficeBearersPage({super.key});

  @override
  State<OfficeBearersPage> createState() => _OfficeBearersPageState();
}

class _OfficeBearersPageState extends State<OfficeBearersPage> {
  List<OfficeBearerModel> _items = [];
  List<MemberModel> _members = [];
  bool _isLoading = true;
  String? _error;

  /// Null = show the year list. Otherwise show that year's committee.
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await OfficeBearerRepo.getAll();
      List<MemberModel> members = _members;
      if (members.isEmpty) {
        try {
          members = await MembersRepo.getMembers(bypassSecurity: true);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _items = items;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool get _isAdmin {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated && s.session.isAdmin;
  }

  String _memberName(String no) {
    for (final m in _members) {
      if (m.no.toUpperCase() == no.toUpperCase()) return m.displayName;
    }
    return no;
  }

  /// First 4-digit number in the text (works for "2024" and "01/01/2024").
  int? _yearOf(String s) {
    final m = RegExp(r'\d{4}').firstMatch(s);
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  /// Years to list, newest first. Covers every start year up to the latest
  /// end year or the current year. Adds an "undated" key when needed.
  List<int> _availableYears(int current) {
    final starts = <int>[];
    var hasUndated = false;
    var maxY = current;
    for (final b in _items) {
      final s = _yearOf(b.termStart);
      if (s == null) {
        hasUndated = true;
        continue;
      }
      starts.add(s);
      if (s > maxY) maxY = s;
      final e = _yearOf(b.termEnd);
      if (e != null && e > maxY) maxY = e;
    }
    final years = <int>[];
    if (starts.isNotEmpty) {
      final minY = starts.reduce((a, b) => a < b ? a : b);
      for (var y = maxY; y >= minY; y--) {
        years.add(y);
      }
    }
    if (hasUndated) years.add(_undatedKey);
    return years;
  }

  /// Bearers whose term covers the given year. A missing end date means "still current".
  List<OfficeBearerModel> _bearersFor(int year, int current) {
    return _items.where((b) {
      final s = _yearOf(b.termStart);
      if (year == _undatedKey) return s == null;
      if (s == null) return false;
      final e = _yearOf(b.termEnd) ?? current;
      return s <= year && year <= e;
    }).toList();
  }

  String _yearTitle(int year) => year == _undatedKey ? 'তারিখ নেই' : '$year';

  /// Opens the dedicated add/edit page. Reloads the list if something was saved.
  Future<void> _openEditor({OfficeBearerModel? existing}) async {
    final saved = await Navigator.push(
      context,
      AddEditOfficeBearerPage.route(existing: existing, members: _members),
    );
    if (saved == true) _load();
  }

  void _confirmDelete(OfficeBearerModel b) {
    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'মুছে ফেলা',
        message: '${b.post} — ${b.memberNo.isNotEmpty ? _memberName(b.memberNo) : b.name} এর তথ্য মুছে ফেলতে চান?',
        confirmText: 'মুছুন',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await OfficeBearerRepo.delete(b.id);
            if (mounted) AppNotifier.showSuccessSnackBar(context, 'মুছে ফেলা হয়েছে');
            _load();
          } catch (e) {
            if (mounted) AppNotifier.showErrorSnackBar(context, e.toString());
          }
        },
      ),
    );
  }

  Widget _buildYearList(List<int> years, int current) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: years.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final y = years[i];
        final count = _bearersFor(y, current).length;
        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedYear = y),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _yearTitle(y),
                      style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '$count জন',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearCommittee(int year, int current, bool isAdmin) {
    final bearers = _bearersFor(year, current);

    // Group by post, in kOfficePosts order; unknown posts go last.
    final groups = <String, List<OfficeBearerModel>>{};
    for (final b in bearers) {
      groups.putIfAbsent(b.post, () => []).add(b);
    }
    final postOrder = [
      ...kOfficePosts.where(groups.containsKey),
      ...groups.keys.where((p) => !kOfficePosts.contains(p)),
    ];

    if (bearers.isEmpty) {
      return const EmptyStateWidget(
        title: 'এই বছরে কোনো দায়িত্বশীল নেই',
        message: 'মেয়াদের তথ্যে এই বছরটি পড়ে এমন কেউ নেই।',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      children: [
        for (final post in postOrder) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              post,
              style: GoogleFonts.notoSansBengali(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          for (final b in groups[post]!)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.memberNo.isNotEmpty ? _memberName(b.memberNo) : b.name,
                          style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'মেয়াদ: ${b.termLabel}${b.isCurrent ? '  •  বর্তমান' : ''}',
                          style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (b.remark.isNotEmpty)
                          Text(
                            'মন্তব্য: ${b.remark}',
                            style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _openEditor(existing: b);
                        if (v == 'delete') _confirmDelete(b);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
                        PopupMenuItem(value: 'delete', child: Text('মুছুন')),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;
    final current = DateTime.now().year;
    final inYear = _selectedYear != null;

    return PopScope(
      // Android back goes to the year list first, then leaves the page.
      canPop: !inYear,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedYear = null);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: inYear
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedYear = null),
                )
              : const CustomBackButton(),
          title: Text(
            inYear ? _yearTitle(_selectedYear!) : 'Managing committee',
            style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.add),
                label: Text('নতুন দায়িত্বশীল', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
                onPressed: () => _openEditor(),
              )
            : null,
        body: GradientBackground(
          child: _isLoading
              ? const Center(child: Loader())
              : _error != null
                  ? ErrorStateWidget(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyStateWidget(
                          title: 'কোনো দায়িত্বশীল যুক্ত নেই',
                          message: 'নতুন দায়িত্বশীল যোগ করলে এখানে জমা থাকবে।',
                        )
                      : inYear
                          ? _buildYearCommittee(_selectedYear!, current, isAdmin)
                          : _buildYearList(_availableYears(current), current),
        ),
      ),
    );
  }
}
