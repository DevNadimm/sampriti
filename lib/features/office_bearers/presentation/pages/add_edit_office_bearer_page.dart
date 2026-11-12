import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/office_bearers/data/models/office_bearer_model.dart';
import 'package:sampriti/features/office_bearers/data/repos/office_bearer_repo.dart';

/// Dedicated add / edit page for a দায়িত্বশীল record. Pops with `true` after a save.
class AddEditOfficeBearerPage extends StatefulWidget {
  final OfficeBearerModel? existing;
  final List<MemberModel> members;

  static Route route({OfficeBearerModel? existing, required List<MemberModel> members}) =>
      MaterialPageRoute(builder: (_) => AddEditOfficeBearerPage(existing: existing, members: members));

  const AddEditOfficeBearerPage({super.key, this.existing, required this.members});

  @override
  State<AddEditOfficeBearerPage> createState() => _AddEditOfficeBearerPageState();
}

class _AddEditOfficeBearerPageState extends State<AddEditOfficeBearerPage> {
  final _formKey = GlobalKey<FormState>();
  late String _post;
  late String _memberNo;
  late final TextEditingController _name;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _remark;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _post = e?.post ?? kOfficePosts.first;
    _memberNo = e?.memberNo ?? '';
    _name = TextEditingController(text: e?.name ?? '');
    _start = TextEditingController(text: e?.termStart ?? '');
    _end = TextEditingController(text: e?.termEnd ?? '');
    _remark = TextEditingController(text: e?.remark ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    _remark.dispose();
    super.dispose();
  }

  void _onMemberChanged(String? no) {
    setState(() {
      _memberNo = no ?? '';
      if (_memberNo.isNotEmpty && _name.text.trim().isEmpty) {
        for (final m in widget.members) {
          if (m.no == _memberNo) _name.text = m.displayName;
        }
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_memberNo.isEmpty && _name.text.trim().isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'সদস্য নির্বাচন করুন অথবা নাম লিখুন');
      return;
    }

    final model = OfficeBearerModel(
      id: widget.existing?.id ?? '',
      post: _post,
      memberNo: _memberNo,
      name: _name.text,
      termStart: _start.text,
      termEnd: _end.text,
      remark: _remark.text,
      createdAt: widget.existing?.createdAt ?? '',
    );

    setState(() => _saving = true);
    try {
      await OfficeBearerRepo.save(model);
      if (!mounted) return;
      AppNotifier.showSuccessSnackBar(context, _isEdit ? 'তথ্য আপডেট হয়েছে' : 'দায়িত্বশীল যুক্ত হয়েছে');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppNotifier.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final memberValue = widget.members.any((m) => m.no == _memberNo) ? _memberNo : null;

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          _isEdit ? 'দায়িত্বশীল সম্পাদনা' : 'নতুন দায়িত্বশীল',
          style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                _label('পদ'),
                DropdownButtonFormField<String>(
                  initialValue: _post,
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  items: kOfficePosts
                      .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.notoSansBengali())))
                      .toList(),
                  onChanged: (v) => setState(() => _post = v ?? _post),
                ),
                const SizedBox(height: 16),

                _label('সদস্য (তালিকা থেকে, ঐচ্ছিক)'),
                DropdownButtonFormField<String>(
                  initialValue: memberValue,
                  isExpanded: true,
                  decoration: _inputDecoration(hint: 'সদস্য নির্বাচন করুন'),
                  items: widget.members
                      .map((m) => DropdownMenuItem(
                            value: m.no,
                            child: Text(
                              '${m.no} - ${m.displayName}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansBengali(),
                            ),
                          ))
                      .toList(),
                  onChanged: _onMemberChanged,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'নাম (সদস্য না হলে বা নিজে লিখতে)',
                  controller: _name,
                  hintText: 'সদস্য না হলে নাম লিখুন',
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'মেয়াদ শুরু (সাল/তারিখ)',
                  controller: _start,
                  hintText: 'যেমন ২০১১',
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'মেয়াদ শেষ (ফাঁকা রাখলে বর্তমান)',
                  controller: _end,
                  hintText: 'যেমন ২০১৪',
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'মন্তব্য',
                  controller: _remark,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                SpringButton(
                  width: double.infinity,
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন',
                    style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
