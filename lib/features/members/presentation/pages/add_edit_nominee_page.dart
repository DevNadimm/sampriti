import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_dropdown_field.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/core/utils/helpers/date_picker_helper.dart';
import 'package:sampriti/core/utils/helpers/image_picker_helper.dart';
import 'package:sampriti/features/members/data/models/nominee_model.dart';

class AddEditNomineePage extends StatefulWidget {
  final NomineeModel? nominee;
  final int? editIndex;

  const AddEditNomineePage({
    super.key,
    this.nominee,
    this.editIndex,
  });

  @override
  State<AddEditNomineePage> createState() => _AddEditNomineePageState();
}

class _AddEditNomineePageState extends State<AddEditNomineePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _fatherController;
  late final TextEditingController _motherController;
  late final TextEditingController _relationController;
  late final TextEditingController _shareController;
  late final TextEditingController _nidController;
  late final TextEditingController _birthController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;

  String? _photo;

  bool get isEditing => widget.nominee != null;

  static const List<String> _quickRelations = [
    'স্ত্রী',
    'স্বামী',
    'পুত্র',
    'কন্যা',
    'পিতা',
    'মাতা',
    'ভাই',
    'বোন',
  ];

  @override
  void initState() {
    super.initState();
    final n = widget.nominee;
    _nameController = TextEditingController(text: n?.name ?? '');
    _fatherController = TextEditingController(text: n?.father ?? '');
    _motherController = TextEditingController(text: n?.mother ?? '');
    _relationController = TextEditingController(text: n?.relation ?? '');
    _shareController = TextEditingController(text: n?.share ?? '100');
    _nidController = TextEditingController(text: n?.nid ?? '');
    _birthController = TextEditingController(text: DateFormatter.ddMMyyyy(n?.birth));
    _mobileController = TextEditingController(text: n?.mobile ?? '');
    _addressController = TextEditingController(text: n?.address ?? '');
    _photo = n?.photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherController.dispose();
    _motherController.dispose();
    _relationController.dispose();
    _shareController.dispose();
    _nidController.dispose();
    _birthController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showPhotoOptions() {
    ImagePickerHelper.showPickerOptions(
      context: context,
      title: 'নমিনীর ছবি নির্বাচন করুন',
      showDelete: _photo != null && _photo!.isNotEmpty,
      onImageSelected: (base64) {
        setState(() => _photo = base64);
      },
      onDelete: () {
        setState(() => _photo = null);
      },
    );
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppNotifier.showErrorSnackBar(context, 'অনুগ্রহ করে নমিনীর নাম লিখুন');
      return;
    }

    final shareText = _shareController.text.trim();
    if (shareText.isNotEmpty) {
      final shareNum = double.tryParse(shareText);
      if (shareNum == null || shareNum <= 0 || shareNum > 100) {
        AppNotifier.showErrorSnackBar(context, 'শেয়ারের অংশ ১ থেকে ১০০-এর মধ্যে হতে হবে');
        return;
      }
    }

    final updated = NomineeModel(
      name: name,
      father: _fatherController.text.trim(),
      mother: _motherController.text.trim(),
      relation: _relationController.text.trim(),
      share: shareText.isEmpty ? '100' : shareText,
      mobile: _mobileController.text.trim(),
      nid: _nidController.text.trim(),
      birth: DateFormatter.yyyyMMdd(_birthController.text.trim()),
      address: _addressController.text.trim(),
      photo: _photo,
    );

    Navigator.pop(context, updated);
  }

  Widget _buildSectionHeader(String title, List<List<dynamic>> icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: icon,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          isEditing ? 'নমিনী তথ্য সম্পাদনা' : 'নতুন নমিনী যোগ করুন',
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
                // 1. Photo Picker Section (Matching AddMemberPage)
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Stack(
                          children: [
                            MemberAvatar(
                              photo: _photo,
                              fallbackText: _nameController.text.isNotEmpty
                                  ? _nameController.text[0]
                                  : 'নমিনী',
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
                        'নমিনীর ছবি নির্বাচন করতে ট্যাপ করুন',
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

                const SizedBox(height: 12),

                // 2. Personal Information Section
                _buildSectionHeader(
                  'ব্যক্তিগত বিবরণ',
                  HugeIcons.strokeRoundedUser,
                ),

                CustomTextField(
                  label: 'নমিনীর পূর্ণ নাম (বাংলায়)',
                  controller: _nameController,
                  isRequired: true,
                  hintText: 'যেমন: মোসাম্মৎ ফাতেমা খাতুন',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                CustomDropdownField(
                  label: 'সম্পর্ক / আত্মীয়তা',
                  controller: _relationController,
                  isRequired: true,
                  hintText: 'সম্পর্ক নির্বাচন করুন',
                  sheetTitle: 'সম্পর্ক / আত্মীয়তা নির্বাচন করুন',
                  options: _quickRelations,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 6),

                // Quick Relationship suggestion chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickRelations.map((rel) {
                    final isSelected = _relationController.text.trim() == rel;
                    return ActionChip(
                      label: Text(
                        rel,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        setState(() {
                          _relationController.text = rel;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                DualFieldRow(
                  left: CustomTextField(
                    label: 'শেয়ারের অংশ (%)',
                    controller: _shareController,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    hintText: '100',
                  ),
                  right: CustomTextField(
                    label: 'মোবাইল নম্বর',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    hintText: '017XXXXXXXX',
                  ),
                ),

                // 3. Family & Identity Section
                _buildSectionHeader(
                  'পারিবারিক ও জাতীয় পরিচয়',
                  HugeIcons.strokeRoundedPassport,
                ),

                DualFieldRow(
                  left: CustomTextField(
                    label: 'পিতার নাম',
                    controller: _fatherController,
                    hintText: 'যেমন: মরহুম আব্দুল করিম',
                  ),
                  right: CustomTextField(
                    label: 'মাতার নাম',
                    controller: _motherController,
                    hintText: 'যেমন: মোসাম্মৎ রহিমা খাতুন',
                  ),
                ),
                const SizedBox(height: 12),

                DualFieldRow(
                  left: CustomTextField(
                    label: 'জাতীয় পরিচয়পত্র / জন্ম নিবন্ধন',
                    controller: _nidController,
                    keyboardType: TextInputType.number,
                    hintText: 'NID অথবা জন্ম নিবন্ধন নং',
                  ),
                  right: CustomTextField(
                    label: 'জন্ম তারিখ',
                    controller: _birthController,
                    readOnly: true,
                    hintText: 'DD/MM/YYYY',
                    suffixIcon: HugeIcons.strokeRoundedCalendar03,
                    onTap: () {
                      DatePickerHelper.show(
                        context: context,
                        controller: _birthController,
                        isBirthDate: true,
                      );
                    },
                  ),
                ),

                // 4. Address Section
                _buildSectionHeader(
                  'ঠিকানা বিবরণ',
                  HugeIcons.strokeRoundedLocation01,
                ),

                CustomTextField(
                  label: 'বর্তমান ও স্থায়ী ঠিকানা',
                  controller: _addressController,
                  hintText: 'গ্রাম/বাড়ি, রোড, ডাকঘর, থানা ও জেলা',
                ),

                const SizedBox(height: 28),

                // 5. Submit Button
                SpringButton(
                  width: double.infinity,
                  onPressed: _onSave,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'নমিনী তথ্য আপডেট করুন' : 'নমিনী সংরক্ষণ করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
