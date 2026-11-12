import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
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
import 'package:sampriti/features/meetings/data/models/meeting_model.dart';
import 'package:sampriti/features/meetings/data/repos/meeting_repo.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';

const String _defaultClosing =
    'সভায় আর কোনো আলোচনা না থাকায় সভাপতি মহোদয় উপস্থিত সকলকে ধন্যবাদ জানিয়ে সভার সমাপ্তি ঘোষণা করেন।';

class AddMeetingPage extends StatefulWidget {
  final MeetingModel? meeting;

  static Route route({MeetingModel? meeting}) =>
      MaterialPageRoute(builder: (_) => AddMeetingPage(meeting: meeting));

  const AddMeetingPage({super.key, this.meeting});

  @override
  State<AddMeetingPage> createState() => _AddMeetingPageState();
}

class _AttendeeCtrl {
  final MemberModel member;
  bool present;
  final TextEditingController designation;
  final TextEditingController signature;

  _AttendeeCtrl(this.member, {this.present = false, String designation = '', String signature = ''})
      : designation = TextEditingController(text: designation),
        signature = TextEditingController(text: signature);

  void dispose() {
    designation.dispose();
    signature.dispose();
  }
}

class _AddMeetingPageState extends State<AddMeetingPage> {
  final _formKey = GlobalKey<FormState>();

  String _type = MeetingType.monthly;
  final _dateCtrl = TextEditingController(text: DateFormatter.ddMMyyyy(DateTime.now()));
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _presidingCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _closingCtrl = TextEditingController(text: _defaultClosing);

  final List<TextEditingController> _agendaCtrls = [];
  final List<TextEditingController> _decisionCtrls = [];
  final List<TextEditingController> _extraCtrls = [];
  List<_AttendeeCtrl> _attendees = [];

  bool _isLoading = true;
  bool _saving = false;

  bool get _isEdit => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final m = widget.meeting;
    List<MemberModel> members = [];
    try {
      members = await MembersRepo.getMembers();
    } catch (e) {
      if (mounted) AppNotifier.showErrorSnackBar(context, e.toString());
    }

    if (m != null) {
      _type = m.type;
      _dateCtrl.text = DateFormatter.ddMMyyyy(m.date);
      _timeCtrl.text = m.time;
      _placeCtrl.text = m.place;
      _presidingCtrl.text = m.presiding;
      _purposeCtrl.text = m.purpose;
      _closingCtrl.text = m.closing.isEmpty ? _defaultClosing : m.closing;
      for (var i = 0; i < m.agendas.length; i++) {
        _agendaCtrls.add(TextEditingController(text: m.agendas[i]));
        _decisionCtrls.add(TextEditingController(
          text: i < m.agendaDecisions.length ? m.agendaDecisions[i] : '',
        ));
      }
      for (final e in m.extraDecisions) {
        _extraCtrls.add(TextEditingController(text: e));
      }
    }
    if (_agendaCtrls.isEmpty) _addAgenda();

    final byNo = {for (final a in m?.attendance ?? const <MeetingAttendee>[]) a.no.toUpperCase(): a};
    _attendees = members.map((mem) {
      final prev = byNo[mem.no.toUpperCase()];
      return _AttendeeCtrl(
        mem,
        present: prev?.present ?? false,
        designation: prev?.designation ?? '',
        signature: prev?.signature ?? '',
      );
    }).toList();

    if (mounted) setState(() => _isLoading = false);
  }

  void _addAgenda() {
    _agendaCtrls.add(TextEditingController());
    _decisionCtrls.add(TextEditingController());
  }

  void _removeAgenda(int i) {
    _agendaCtrls.removeAt(i).dispose();
    _decisionCtrls.removeAt(i).dispose();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _placeCtrl.dispose();
    _presidingCtrl.dispose();
    _purposeCtrl.dispose();
    _closingCtrl.dispose();
    for (final c in [..._agendaCtrls, ..._decisionCtrls, ..._extraCtrls]) {
      c.dispose();
    }
    for (final a in _attendees) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final agendas = <String>[];
    final decisions = <String>[];
    for (var i = 0; i < _agendaCtrls.length; i++) {
      final a = _agendaCtrls[i].text.trim();
      if (a.isEmpty) continue;
      agendas.add(a);
      decisions.add(_decisionCtrls[i].text.trim());
    }
    if (agendas.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'কমপক্ষে একটি এজেন্ডা লিখুন');
      return;
    }

    final meeting = MeetingModel(
      id: widget.meeting?.id ?? '',
      type: _type,
      date: _dateCtrl.text.trim(),
      time: _timeCtrl.text,
      place: _placeCtrl.text,
      presiding: _presidingCtrl.text,
      purpose: _purposeCtrl.text,
      agendas: agendas,
      agendaDecisions: decisions,
      extraDecisions: _extraCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      attendance: _attendees
          .map((a) => MeetingAttendee(
                no: a.member.no,
                name: a.member.displayName,
                designation: a.designation.text.trim(),
                present: a.present,
                signature: a.signature.text.trim(),
              ))
          .toList(),
      closing: _closingCtrl.text,
      createdAt: widget.meeting?.createdAt ?? '',
    );

    setState(() => _saving = true);
    try {
      await MeetingRepo.saveMeeting(meeting);
      if (!mounted) return;
      AppNotifier.showSuccessSnackBar(context, _isEdit ? 'সভা আপডেট হয়েছে' : 'সভা সংরক্ষণ হয়েছে');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppNotifier.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          t,
          style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          _isEdit ? 'সভা সম্পাদনা' : 'নতুন মিটিং রেজুলেশন',
          style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                      _sectionTitle('১. সভার ধরণ ও বিবরণ'),
                      _label('সভার ধরণ'),
                      const SizedBox(height: 6),
                      Row(children: [
                        for (final t in [MeetingType.monthly, MeetingType.emergency, MeetingType.agm]) ...[
                          Expanded(
                            child: SelectableChip(
                              label: MeetingType.label(t),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              fontSize: 11,
                              isSelected: _type == t,
                              onSelected: () => setState(() => _type = t),
                            ),
                          ),
                          if (t != MeetingType.agm) const SizedBox(width: 6),
                        ],
                      ]),
                      const SizedBox(height: 12),
                      DualFieldRow(
                        left: CustomTextField(
                          label: 'তারিখ',
                          controller: _dateCtrl,
                          isRequired: true,
                          readOnly: true,
                          hintText: 'DD/MM/YYYY',
                          suffixIcon: HugeIcons.strokeRoundedCalendar03,
                          onTap: () => DatePickerHelper.show(context: context, controller: _dateCtrl),
                        ),
                        right: CustomTextField(
                          label: 'সময়',
                          controller: _timeCtrl,
                          hintText: 'যেমন: সকাল ১০:০০ টা',
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(label: 'স্থান', controller: _placeCtrl, hintText: 'যেমন: নোয়াপাড়া আইডিয়াল স্কুল, রাউজান'),
                      const SizedBox(height: 12),
                      CustomTextField(label: 'সভাপতিত্বে', controller: _presidingCtrl, hintText: 'সভাপতির নাম'),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'সভার উদ্দেশ্য',
                        controller: _purposeCtrl,
                        maxLines: 2,
                        hintText: 'কেন এই সভা ডাকা হয়েছে',
                      ),

                      _sectionTitle('২. সভার এজেন্ডা ও এজেন্ডাভিত্তিক সিদ্ধান্ত'),
                      for (var i = 0; i < _agendaCtrls.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: 'এজেন্ডা ${i + 1}',
                                    controller: _agendaCtrls[i],
                                  ),
                                ),
                                if (_agendaCtrls.length > 1)
                                  IconButton(
                                    tooltip: 'মুছুন',
                                    icon: const Icon(Icons.close, color: AppColors.error),
                                    onPressed: () => setState(() => _removeAgenda(i)),
                                  ),
                              ]),
                              const SizedBox(height: 8),
                              CustomTextField(
                                label: 'এজেন্ডা ${i + 1}-এর সিদ্ধান্ত',
                                controller: _decisionCtrls[i],
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(_addAgenda),
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        label: Text('এজেন্ডা যোগ করুন', style: GoogleFonts.notoSansBengali(color: AppColors.primary)),
                      ),

                      _sectionTitle('৩. অতিরিক্ত সিদ্ধান্ত'),
                      for (var i = 0; i < _extraCtrls.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Expanded(
                              child: CustomTextField(label: 'অতিরিক্ত সিদ্ধান্ত ${i + 1}', controller: _extraCtrls[i], maxLines: 2),
                            ),
                            IconButton(
                              tooltip: 'মুছুন',
                              icon: const Icon(Icons.close, color: AppColors.error),
                              onPressed: () => setState(() => _extraCtrls.removeAt(i).dispose()),
                            ),
                          ]),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(() => _extraCtrls.add(TextEditingController())),
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        label: Text('সিদ্ধান্ত যোগ করুন', style: GoogleFonts.notoSansBengali(color: AppColors.primary)),
                      ),

                      _sectionTitle('৪. উপস্থিতি ও স্বাক্ষর'),
                      if (_attendees.isEmpty)
                        Text(
                          'কোনো সদস্য পাওয়া যায়নি',
                          style: GoogleFonts.notoSansBengali(color: AppColors.textSecondary),
                        ),
                      for (final a in _attendees)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: a.present ? AppColors.success.withValues(alpha: 0.08) : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  '${a.member.no} · ${a.member.displayName}',
                                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
                                ),
                                value: a.present,
                                onChanged: (v) => setState(() => a.present = v ?? false),
                              ),
                              Row(children: [
                                Expanded(
                                  child: CustomTextField(label: 'পদবী', controller: a.designation, hintText: 'যেমন: সভাপতি'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(label: 'স্বাক্ষর (নাম)', controller: a.signature),
                                ),
                              ]),
                            ],
                          ),
                        ),

                      _sectionTitle('৫. সমাপ্তি ঘোষণা'),
                      CustomTextField(label: 'সমাপ্তি ঘোষণা', controller: _closingCtrl, maxLines: 3),

                      const SizedBox(height: 24),
                      SpringButton(
                        width: double.infinity,
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? 'সংরক্ষণ হচ্ছে...' : 'সভা সংরক্ষণ করুন',
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
}
