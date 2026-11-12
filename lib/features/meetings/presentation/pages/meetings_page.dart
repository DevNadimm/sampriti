import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/meetings/data/models/meeting_model.dart';
import 'package:sampriti/features/meetings/data/repos/meeting_repo.dart';
import 'package:sampriti/features/meetings/presentation/pages/add_meeting_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeetingsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const MeetingsPage());

  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  List<MeetingModel> _meetings = [];
  bool _isLoading = true;
  String? _error;

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
      final list = await MeetingRepo.getMeetings();
      if (mounted) {
        setState(() {
          _meetings = list;
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

  Future<void> _openEditor([MeetingModel? meeting]) async {
    final saved = await Navigator.push(context, AddMeetingPage.route(meeting: meeting));
    if (saved == true) _load();
  }

  void _openPdf(MeetingModel m) {
    Navigator.push(
      context,
      PdfPreviewPage.route(
        title: 'মিটিং রেজুলেশন (${m.uiDate})',
        pdfFileName: 'sampriti-meeting-${m.date}.pdf',
        buildPdf: () => PdfDocumentService.generateMeetingResolutionPdf(m),
      ),
    );
  }

  void _confirmDelete(MeetingModel m) {
    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'সভা মুছে ফেলা',
        message: '${m.uiDate} তারিখের ${m.typeLabel} মুছে ফেলতে চান? এটি ফেরত আনা যাবে না।',
        confirmText: 'মুছুন',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await MeetingRepo.deleteMeeting(m.id);
            if (mounted) AppNotifier.showSuccessSnackBar(context, 'সভা মুছে ফেলা হয়েছে');
            _load();
          } catch (e) {
            if (mounted) AppNotifier.showErrorSnackBar(context, e.toString());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'মিটিং রেজুলেশন',
          style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: Text('নতুন সভা', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
              onPressed: () => _openEditor(),
            )
          : null,
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: Loader())
            : _error != null
                ? ErrorStateWidget(message: _error!, onRetry: _load)
                : _meetings.isEmpty
                    ? const EmptyStateWidget(
                        title: 'কোনো সভা নেই',
                        message: 'নতুন সভা যোগ করলে এখানে জমা থাকবে।',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _meetings.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final m = _meetings[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                onTap: () => _openPdf(m),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                title: Text(
                                  '${m.typeLabel}  •  ${m.uiDate}',
                                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                subtitle: Text(
                                  [
                                    if (m.place.isNotEmpty) m.place,
                                    'এজেন্ডা: ${m.agendas.length}টি',
                                    'উপস্থিত: ${m.presentCount} জন',
                                  ].join('  •  '),
                                  style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                trailing: isAdmin
                                    ? PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') _openEditor(m);
                                          if (v == 'delete') _confirmDelete(m);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
                                          const PopupMenuItem(value: 'delete', child: Text('মুছুন')),
                                        ],
                                      )
                                    : const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
