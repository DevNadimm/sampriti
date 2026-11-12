import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/presentation/bloc/sector_bloc.dart';

class AddEditSectorPage extends StatefulWidget {
  final SectorType type;
  final SectorModel? sector;

  static Route route({required SectorType type, SectorModel? sector}) => MaterialPageRoute(
        builder: (_) => AddEditSectorPage(type: type, sector: sector),
      );

  const AddEditSectorPage({
    super.key,
    required this.type,
    this.sector,
  });

  @override
  State<AddEditSectorPage> createState() => _AddEditSectorPageState();
}

class _AddEditSectorPageState extends State<AddEditSectorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late bool _isActive;

  bool get isEditing => widget.sector != null;
  String get _singularLabel => widget.type == SectorType.income ? 'আয়ের খাত' : 'ব্যয়ের খাত';

  @override
  void initState() {
    super.initState();
    final s = widget.sector;
    _nameController = TextEditingController(text: s?.name ?? '');
    _descController = TextEditingController(text: s?.description ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveSector() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isSys = widget.sector?.isSystem ?? false;

    final updated = (widget.sector ??
            SectorModel(
              id: '',
              name: '',
              type: widget.type,
              key: SectorModel.keyCustom,
              isSystem: false,
              createdAt: DateTime.now().toIso8601String(),
            ))
        .copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      type: widget.type,
      isActive: _isActive,
      key: isSys ? widget.sector!.key : SectorModel.keyCustom,
      isSystem: isSys,
    );

    context.read<SectorBloc>().add(SectorSaveRequested(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SectorBloc, SectorState>(
      listener: (context, state) {
        if (state is SectorActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
          Navigator.pop(context);
        } else if (state is SectorFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            isEditing ? '$_singularLabel সম্পাদনা' : 'নতুন $_singularLabel তৈরি',
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
                  // Sector Name Field
                  CustomTextField(
                    label: '$_singularLabel-এর নাম',
                    controller: _nameController,
                    isRequired: true,
                    hintText: widget.type == SectorType.income
                        ? 'যেমন: প্রজেক্ট লভ্যাংশ, শেয়ার বিনিয়োগ'
                        : 'যেমন: অফিস ভাড়া, কর্মচারী বেতন, আপ্যায়ন',
                    suffixIcon: widget.type == SectorType.income
                        ? HugeIcons.strokeRoundedArrowDownLeft01
                        : HugeIcons.strokeRoundedArrowUpRight01,
                  ),
                  const SizedBox(height: 16),

                  // Sector Status
                  Text(
                    'খাতের অবস্থা (Status)',
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
                          label: 'সক্রিয় (Active)',
                          isSelected: _isActive,
                          onSelected: () => setState(() => _isActive = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableChip(
                          label: 'নিষ্ক্রিয় (Inactive)',
                          isSelected: !_isActive,
                          onSelected: () => setState(() => _isActive = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sector Description
                  CustomTextField(
                    label: 'বিবরণ ও উদ্দেশ্য (ঐচ্ছিক)',
                    controller: _descController,
                    hintText: 'এই খাতের বিস্তারিত বিবরণ লিখুন...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  // Submit Button (RentBook SpringButton)
                  BlocBuilder<SectorBloc, SectorState>(
                    builder: (context, state) {
                      final isLoading = state is SectorLoading;
                      return SpringButton(
                        width: double.infinity,
                        onPressed: isLoading ? null : _saveSector,
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
                                isEditing ? '$_singularLabel আপডেট করুন' : '$_singularLabel সংরক্ষণ করুন',
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
