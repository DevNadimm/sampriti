import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/dual_field_row.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/core/utils/helpers/date_picker_helper.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/presentation/bloc/project_bloc.dart';
import 'package:sampriti/features/setup/presentation/widgets/member_multi_select_sheet.dart';

class AddEditProjectPage extends StatefulWidget {
  final ProjectModel? project;

  static Route route({ProjectModel? project}) => MaterialPageRoute(
        builder: (_) => AddEditProjectPage(project: project),
      );

  const AddEditProjectPage({super.key, this.project});

  @override
  State<AddEditProjectPage> createState() => _AddEditProjectPageState();
}

class _AddEditProjectPageState extends State<AddEditProjectPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final TextEditingController _budgetController;
  late final TextEditingController _descController;

  late String _status;
  late List<String> _selectedMemberNos;
  List<MemberModel> _allMembers = [];
  bool _isLoadingMembers = true;

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameController = TextEditingController(text: p?.name ?? '');
    _dateController = TextEditingController(
      text: p != null && p.startDate.isNotEmpty
          ? DateFormatter.ddMMyyyy(p.startDate)
          : DateFormatter.ddMMyyyy(DateTime.now()),
    );
    _budgetController = TextEditingController(
      text: p != null && p.budget > 0 ? p.budget.round().toString() : '',
    );
    _descController = TextEditingController(text: p?.description ?? '');
    _status = p?.status ?? 'active';
    _selectedMemberNos = p != null ? List<String>.from(p.memberNos) : [];

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await MembersRepo.getMembers(bypassSecurity: true);
      if (mounted) {
        setState(() {
          _allMembers = members;
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _openMemberPicker() async {
    final result = await MemberMultiSelectSheet.show(
      context: context,
      initialSelectedMemberNos: _selectedMemberNos,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedMemberNos = result;
      });
    }
  }

  void _removeMember(String memberNo) {
    setState(() {
      _selectedMemberNos.remove(memberNo);
    });
  }

  void _saveProject() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    final updated = (widget.project ??
            ProjectModel(
              id: '',
              name: '',
              createdAt: DateTime.now().toIso8601String(),
            ))
        .copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      startDate: DateFormatter.yyyyMMdd(_dateController.text.trim()),
      budget: budget,
      status: _status,
      memberNos: _selectedMemberNos,
    );

    context.read<ProjectBloc>().add(ProjectSaveRequested(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
          Navigator.pop(context);
        } else if (state is ProjectFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            isEditing ? 'প্রকল্প সম্পাদনা' : 'নতুন প্রকল্প তৈরি',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: GradientBackground(
          child: _isLoadingMembers
              ? const Center(child: Loader())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project Name Field
                        CustomTextField(
                          label: 'প্রকল্পের নাম',
                          controller: _nameController,
                          isRequired: true,
                          hintText: 'যেমন: আধুনিক ডেইরি ও কৃষি প্রকল্প',
                          suffixIcon: HugeIcons.strokeRoundedBriefcase02,
                        ),
                        const SizedBox(height: 16),

                        // Date and Budget Row
                        DualFieldRow(
                          left: CustomTextField(
                            label: 'শুরুর তারিখ',
                            controller: _dateController,
                            isRequired: true,
                            readOnly: true,
                            hintText: 'DD/MM/YYYY',
                            suffixIcon: HugeIcons.strokeRoundedCalendar03,
                            onTap: () => DatePickerHelper.show(
                              context: context,
                              controller: _dateController,
                            ),
                          ),
                          right: CustomTextField(
                            label: 'প্রত্যাশিত বাজেট (টাকা)',
                            controller: _budgetController,
                            hintText: 'ঐচ্ছিক, যেমন: ৫০০০০০',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Project Status Selector
                        Text(
                          'প্রকল্পের বর্তমান অবস্থা (Status)',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableChip(
                                label: 'চলমান (Active)',
                                isSelected: _status == 'active',
                                onSelected: () => setState(() => _status = 'active'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableChip(
                                label: 'সমাপ্ত (Completed)',
                                isSelected: _status == 'completed',
                                onSelected: () => setState(() => _status = 'completed'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Member Selection Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.inputBorder, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'প্রকল্পের সদস্য / অংশীদার',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'অ্যাপের শেয়ারহোল্ডারদের মধ্য থেকে যুক্ত করুন',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _openMemberPicker,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedUserAdd01,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    label: Text(
                                      _selectedMemberNos.isEmpty ? 'সদস্য যোগ করুন' : 'পরিবর্তন (${_selectedMemberNos.length})',
                                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (_selectedMemberNos.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.greyLight.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.inputBorder,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const HugeIcon(
                                        icon: HugeIcons.strokeRoundedUserGroup,
                                        size: 28,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'কোন সদস্য এখনো যুক্ত করা হয়নি',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'উপরে "সদস্য যোগ করুন" বাটনে চাপুন',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 11,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedMemberNos.map((no) {
                                    final member = _allMembers.firstWhere(
                                      (m) => m.no == no,
                                      orElse: () => MemberModel(no: no, nameBn: no),
                                    );

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MemberAvatar(
                                            photo: member.photo,
                                            fallbackText: member.no,
                                            size: 22,
                                            isCircle: true,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${member.no} • ${member.displayName}',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => _removeMember(no),
                                            behavior: HitTestBehavior.opaque,
                                            child: const Padding(
                                              padding: EdgeInsets.all(2),
                                              child: HugeIcon(
                                                icon: HugeIcons.strokeRoundedCancel01,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Project Description / Note
                        CustomTextField(
                          label: 'প্রকল্পের বিবরণ ও উদ্দেশ্য',
                          controller: _descController,
                          hintText: 'প্রকল্পের বিস্তারিত কর্মপরিকল্পনা, স্থান বা অন্যান্য তথ্য...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        BlocBuilder<ProjectBloc, ProjectState>(
                          builder: (context, state) {
                            final isLoading = state is ProjectLoading;
                            return SpringButton(
                              width: double.infinity,
                              onPressed: isLoading ? null : _saveProject,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Text(
                                      isEditing ? 'প্রকল্প আপডেট করুন' : 'প্রকল্প সংরক্ষণ করুন',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            );
                          },
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
}
