import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/announcements/data/models/announcement_model.dart';
import 'package:sampriti/features/announcements/data/repos/announcement_repo.dart';
import 'package:sampriti/features/announcements/presentation/pages/add_edit_announcement_page.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Live list of announcements. Admin can create, edit and delete;
/// shareholders see a read-only list.
class AnnouncementsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const AnnouncementsPage());

  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  late Stream<List<AnnouncementModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = AnnouncementRepo.watchAnnouncements();
  }

  void _retry() => setState(() => _stream = AnnouncementRepo.watchAnnouncements());

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.session.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Announcements',
          style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: Text('New', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
              onPressed: () => Navigator.push(context, AddEditAnnouncementPage.route()),
            )
          : null,
      body: GradientBackground(
        child: StreamBuilder<List<AnnouncementModel>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorStateWidget(
                message: 'ঘোষণা লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।',
                onRetry: _retry,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Loader());
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return const EmptyStateWidget(
                title: 'No announcements',
                message: 'New announcements will appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AnnouncementTile(item: items[i], isAdmin: isAdmin),
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel item;
  final bool isAdmin;

  const _AnnouncementTile({required this.item, required this.isAdmin});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Delete announcement',
        message: '"${item.title}" will be deleted permanently. Continue?',
        confirmText: 'Delete',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(dialogContext);
          try {
            await AnnouncementRepo.deleteAnnouncement(item.id);
            if (context.mounted) AppNotifier.showSuccessSnackBar(context, 'Announcement deleted');
          } catch (e) {
            if (context.mounted) AppNotifier.showErrorSnackBar(context, e.toString());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt != null ? DateFormat('d MMM yyyy').format(item.createdAt!) : '';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_outlined, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: GoogleFonts.notoSansBengali(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.push(context, AddEditAnnouncementPage.route(announcement: item));
                }
                if (v == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}
