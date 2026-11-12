import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/core/utils/helpers/date_picker_helper.dart';
import 'package:sampriti/core/utils/helpers/hash_helper.dart';
import 'package:sampriti/core/utils/helpers/image_picker_helper.dart';
import 'package:sampriti/core/utils/helpers/option_picker_bottom_sheet_helper.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/models/nominee_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/members/presentation/bloc/member_bloc.dart';
import 'package:sampriti/features/members/presentation/pages/add_edit_nominee_page.dart';

class AddMemberPage extends StatefulWidget {
  final MemberModel? member;

  static Route route({MemberModel? member}) => MaterialPageRoute(
        builder: (_) => AddMemberPage(member: member),
      );

  const AddMemberPage({super.key, this.member});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _noController;
  late final TextEditingController _nameBnController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _mobileController;
  late final TextEditingController _nidController;
  late final TextEditingController _birthController;
  late final TextEditingController _fatherController;
  late final TextEditingController _motherController;
  late final TextEditingController _spouseController;
  late final TextEditingController _jobController;
  late final TextEditingController _addressController;
  late final TextEditingController _sharesController;
  late final TextEditingController _pinController;

  late bool _founder;
  late bool _labor;
  late List<NomineeModel> _nominees;
  String? _photo;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _photo = m?.photo;
    _noController = TextEditingController(text: m?.no ?? '');
    _nameBnController = TextEditingController(text: m?.nameBn ?? '');
    _nameEnController = TextEditingController(text: m?.nameEn ?? '');
    _mobileController = TextEditingController(text: m?.mobile ?? '');
    _nidController = TextEditingController(text: m?.nid ?? '');
    _birthController = TextEditingController(text: DateFormatter.ddMMyyyy(m?.birth));
    _fatherController = TextEditingController(text: m?.father ?? '');
    _motherController = TextEditingController(text: m?.mother ?? '');
    _spouseController = TextEditingController(text: m?.spouse ?? '');
    _jobController = TextEditingController(text: m?.job ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _sharesController = TextEditingController(text: (m?.shares ?? 1).toString());
    _pinController = TextEditingController(text: m?.plainPin ?? '');

    _founder = m?.founder ?? false;
    _labor = m?.labor ?? false;
    _nominees = m != null ? List.from(m.nominees) : [];

    if (m == null) {
      _fetchNextNo();
    }
  }

  Future<void> _fetchNextNo() async {
    final next = await MembersRepo.getNextMemberNo();
    if (mounted && _noController.text.isEmpty) {
      setState(() {
        _noController.text = next;
      });
    }
  }

  @override
  void dispose() {
    _noController.dispose();
    _nameBnController.dispose();
    _nameEnController.dispose();
    _mobileController.dispose();
    _nidController.dispose();
    _birthController.dispose();
    _fatherController.dispose();
    _motherController.dispose();
    _spouseController.dispose();
    _jobController.dispose();
    _addressController.dispose();
    _sharesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showPhotoOptions() {
    ImagePickerHelper.showPickerOptions(
      context: context,
      title: 'সদস্যের ছবি নির্বাচন করুন',
      showDelete: _photo != null && _photo!.isNotEmpty,
      onImageSelected: (base64) {
        setState(() => _photo = base64);
      },
      onDelete: () {
        setState(() => _photo = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;

    return BlocListener<MemberBloc, MemberState>(
      listener: (context, state) {
        if (state is MemberActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
          Navigator.pop(context);
        } else if (state is MemberFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            isEditing ? 'সদস্য তথ্য সম্পাদনা' : 'নতুন সদস্য নিবন্ধন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
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
                  // Photo Picker Section (Matching Nominee Field)
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Stack(
                            children: [
                              MemberAvatar(
                                photo: _photo,
                                fallbackText: _noController.text.isNotEmpty ? _noController.text : 'সদস্য',
                                width: 84,
                                height: 104,
                                isCircle: false,
                                borderRadius: 12,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2.5,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedCamera01,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'সদস্যের ছবি নির্বাচন করতে ট্যাপ করুন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '(পাসপোর্ট সাইজ ছবি ৩.৫ × ৪.৫ সেমি)',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DualFieldRow(
                    left: CustomTextField(
                      label: 'শেয়ার নম্বর (ID)',
                      controller: _noController,
                      isRequired: true,
                      readOnly: isEditing,
                      hintText: 'S101',
                    ),
                    right: CustomTextField(
                      label: 'শেয়ার সংখ্যা',
                      controller: _sharesController,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      hintText: '1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'নাম (বাংলায়)',
                    controller: _nameBnController,
                    isRequired: true,
                    hintText: 'যেমন: মোঃ আব্দুর রহিম',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'নাম (ইংরেজি)',
                    controller: _nameEnController,
                    hintText: 'e.g. Md. Abdur Rahim',
                  ),
                  const SizedBox(height: 12),
                  DualFieldRow(
                    left: CustomTextField(
                      label: 'মোবাইল নম্বর',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      hintText: '017XXXXXXXX',
                    ),
                    right: CustomTextField(
                      label: 'জাতীয় পরিচয়পত্র (NID)',
                      controller: _nidController,
                      keyboardType: TextInputType.number,
                      hintText: 'NID নম্বর',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DualFieldRow(
                    left: CustomTextField(
                      label: 'পিতা',
                      controller: _fatherController,
                      hintText: 'পিতার নাম',
                    ),
                    right: CustomTextField(
                      label: 'মাতা',
                      controller: _motherController,
                      hintText: 'মাতার নাম',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DualFieldRow(
                    left: CustomTextField(
                      label: 'স্বামী / স্ত্রী',
                      controller: _spouseController,
                      hintText: 'স্বামী বা স্ত্রীর নাম',
                    ),
                    right: CustomTextField(
                      label: 'জন্ম তারিখ',
                      controller: _birthController,
                      readOnly: true,
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: HugeIcons.strokeRoundedCalendar03,
                      onTap: () => DatePickerHelper.show(
                        context: context,
                        controller: _birthController,
                        isBirthDate: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'পেশা',
                    controller: _jobController,
                    hintText: 'যেমন: ব্যবসায়ী, শিক্ষক',
                    suffixIcon: HugeIcons.strokeRoundedArrowDown01,
                    onSuffixTap: () {
                      OptionPickerBottomSheetHelper.show(
                        context: context,
                        title: 'পেশা নির্বাচন করুন',
                        options: const [
                          'ব্যবসা',
                          'চাকরি',
                          'শিক্ষক',
                          'কৃষি',
                          'প্রবাসী',
                          'আইনজীবী',
                          'চিকিৎসক',
                          'অন্যান্য',
                        ],
                        controller: _jobController,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'ঠিকানা',
                    controller: _addressController,
                    hintText: 'বর্তমান ও স্থায়ী ঠিকানা',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'লগইন পিন (PIN) — ৪-৬ ডিজিট',
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    hintText: 'যেমন: 1234 (শেয়ারহোল্ডারের লগইন পিন)',
                    validator: (val) {
                      if (val != null && val.toString().trim().isNotEmpty) {
                        final trimmed = val.toString().trim();
                        if (trimmed.length < 4 || trimmed.length > 6) {
                          return 'পিন ৪ থেকে ৬ ডিজিটের হতে হবে';
                        }
                        if (int.tryParse(trimmed) == null) {
                          return 'শুধুমাত্র সংখ্যা (0-9) প্রবেশ করান';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Switches: Founder & Labor
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.primary,
                          title: Text(
                            'প্রতিষ্ঠাতা সদস্য (Founder 20% Pool)',
                            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          value: _founder,
                          onChanged: (val) => setState(() => _founder = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.success,
                          title: Text(
                            'শ্রমদাতা সদস্য (Labor 20% Pool)',
                            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          value: _labor,
                          onChanged: (val) => setState(() => _labor = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nominees Section
                  _buildNomineesEditor(),
                  const SizedBox(height: 24),

                  // Submit Button
                  SpringButton(
                    width: double.infinity,
                    onPressed: _saveMember,
                    child: Text(
                      isEditing ? 'পরিবর্তন সংরক্ষণ করুন' : 'সদস্য যোগ করুন',
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

  Widget _buildNomineesEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'মনোনীত নমিনী (${_nominees.length} জন)',
                style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              TextButton.icon(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircleHalfDot, size: 16, color: AppColors.primary),
                label: Text(
                  'নমিনী যোগ',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                onPressed: () => _openNomineePage(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_nominees.isEmpty)
            Text(
              'কোনো নমিনী যোগ করা হয়নি। ওপরের বাটন চেপে নমিনী যোগ করতে পারেন।',
              style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nominees.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final n = _nominees[index];
                return Row(
                  children: [
                    MemberAvatar(
                      photo: n.photo,
                      fallbackText: n.name.isNotEmpty ? n.name[0] : 'ন',
                      width: 44,
                      height: 52,
                      isCircle: false,
                      borderRadius: 6,
                      border: Border.all(color: AppColors.border),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${n.name} (${n.relation}) - ${n.share}%',
                            style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'মোবাইল: ${n.mobile.isNotEmpty ? n.mobile : "—"} | NID: ${n.nid.isNotEmpty ? n.nid : "—"}',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 18, color: AppColors.primary),
                      onPressed: () => _openNomineePage(editIndex: index),
                    ),
                    IconButton(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 18, color: AppColors.error),
                      onPressed: () {
                        setState(() => _nominees.removeAt(index));
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openNomineePage({int? editIndex}) async {
    final existing = editIndex != null ? _nominees[editIndex] : null;
    final result = await Navigator.push<NomineeModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditNomineePage(
          nominee: existing,
          editIndex: editIndex,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (editIndex == null) {
          _nominees.add(result);
        } else {
          _nominees[editIndex] = result;
        }
      });
    }
  }

  void _saveMember() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final plainPin = _pinController.text.trim();
    String? hashedPin = widget.member?.pin;
    if (plainPin.isNotEmpty) {
      hashedPin = HashHelper.fastHash('${_noController.text.trim().toUpperCase()}|$plainPin');
    }

    final member = MemberModel(
      no: _noController.text.trim().toUpperCase(),
      nameBn: _nameBnController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      mobile: _mobileController.text.trim(),
      nid: _nidController.text.trim(),
      birth: DateFormatter.yyyyMMdd(_birthController.text.trim()),
      father: _fatherController.text.trim(),
      mother: _motherController.text.trim(),
      spouse: _spouseController.text.trim(),
      job: _jobController.text.trim(),
      address: _addressController.text.trim(),
      shares: int.tryParse(_sharesController.text.trim()) ?? 1,
      founder: _founder,
      labor: _labor,
      pin: hashedPin,
      plainPin: plainPin.isNotEmpty ? plainPin : widget.member?.plainPin,
      photo: _photo,
      nominees: _nominees,
    );

    context.read<MemberBloc>().add(MemberSaveRequested(member));
  }
}
