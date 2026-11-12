import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/announcements/data/models/announcement_model.dart';
import 'package:sampriti/features/announcements/data/repos/announcement_repo.dart';

/// Create or edit an announcement. Pops with `true` after a successful save.
class AddEditAnnouncementPage extends StatefulWidget {
  static Route route({AnnouncementModel? announcement}) =>
      MaterialPageRoute(builder: (_) => AddEditAnnouncementPage(announcement: announcement));

  final AnnouncementModel? announcement;

  const AddEditAnnouncementPage({super.key, this.announcement});

  @override
  State<AddEditAnnouncementPage> createState() => _AddEditAnnouncementPageState();
}

class _AddEditAnnouncementPageState extends State<AddEditAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _saving = false;

  bool get _isEdit => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.announcement?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.announcement?.body ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AnnouncementRepo.saveAnnouncement(
        AnnouncementModel(
          id: widget.announcement?.id ?? '',
          title: _titleCtrl.text,
          body: _bodyCtrl.text,
        ),
      );
      if (!mounted) return;
      AppNotifier.showSuccessSnackBar(context, _isEdit ? 'ঘোষণা আপডেট হয়েছে' : 'ঘোষণা প্রকাশিত হয়েছে');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppNotifier.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          _isEdit ? 'Edit Announcement' : 'New Announcement',
          style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: GradientBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextFormField(
                controller: _titleCtrl,
                maxLength: 100,
                style: GoogleFonts.notoSansBengali(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.notoSansBengali(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyCtrl,
                minLines: 5,
                maxLines: 12,
                style: GoogleFonts.notoSansBengali(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  labelStyle: GoogleFonts.notoSansBengali(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Publish',
                          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
