import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/shimmer/shimmer_list.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/presentation/bloc/sector_bloc.dart';
import 'package:sampriti/features/setup/presentation/pages/add_edit_sector_page.dart';
import 'package:sampriti/features/setup/presentation/widgets/sector_card.dart';

class SectorsPage extends StatefulWidget {
  final SectorType type;

  static Route route({required SectorType type}) => MaterialPageRoute(
        builder: (_) => SectorsPage(type: type),
      );

  const SectorsPage({super.key, required this.type});

  @override
  State<SectorsPage> createState() => _SectorsPageState();
}

class _SectorsPageState extends State<SectorsPage> {
  final TextEditingController _searchController = TextEditingController();

  String get _title => widget.type == SectorType.income ? 'আয়ের খাতসমূহ' : 'ব্যয়ের খাতসমূহ';
  String get _singularLabel => widget.type == SectorType.income ? 'আয়ের খাত' : 'ব্যয়ের খাত';

  @override
  void initState() {
    super.initState();
    context.read<SectorBloc>().add(SectorFetchRequested(widget.type));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddSector() {
    Navigator.push(context, AddEditSectorPage.route(type: widget.type));
  }

  void _onEditSector(SectorModel sector) {
    if (sector.isSystem) return;
    Navigator.push(context, AddEditSectorPage.route(type: widget.type, sector: sector));
  }

  void _onDeleteSector(SectorModel sector) {
    if (sector.isSystem) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'সিস্টেম খাত',
            style: GoogleFonts.notoSansBengali(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            '"${sector.name}" একটি স্থায়ী সিস্টেম খাত যা স্বয়ংক্রিয় ভাউচার ও লভ্যাংশ হিসাবের জন্য সংরক্ষিত। এটি মুছে ফেলা সম্ভব নয়।',
            style: GoogleFonts.notoSansBengali(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'ঠিক আছে',
                style: GoogleFonts.notoSansBengali(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    AppConfirmationDialog.show(
      context,
      title: '$_singularLabel মুছে ফেলুন',
      message: 'আপনি কি নিশ্চিত যে "${sector.name}" খাতটি মুছে ফেলতে চান?',
      confirmText: 'মুছে ফেলুন',
      isDestructive: true,
      onConfirm: () {
        context.read<SectorBloc>().add(SectorDeleteRequested(id: sector.id, type: widget.type));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SectorBloc, SectorState>(
      listener: (context, state) {
        if (state is SectorActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
        } else if (state is SectorFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            _title,
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: GradientBackground(
          child: Column(
            children: [
              // Search Header (RentBook Style)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: CustomTextField.search(
                  controller: _searchController,
                  hintText: '$_singularLabel খুঁজুন (নাম বা বিবরণ)...',
                  onChanged: (val) {
                    context.read<SectorBloc>().add(SectorSearchRequested(val));
                  },
                ),
              ),

              // Content Area
              Expanded(
                child: BlocBuilder<SectorBloc, SectorState>(
                  builder: (context, state) {
                    if (state is SectorLoading || state is SectorInitial) {
                      return const ShimmerList(
                        itemCount: 6,
                        itemHeight: 110,
                      );
                    }

                    if (state is SectorFailure && state is! SectorLoaded) {
                      return ErrorStateWidget(
                        message: state.message,
                        onRetry: () => context.read<SectorBloc>().add(SectorFetchRequested(widget.type)),
                      );
                    }

                    if (state is SectorLoaded) {
                      final sectors = state.filteredSectors;

                      if (sectors.isEmpty) {
                        return Center(
                          child: EmptyStateWidget(
                            title: 'কোন $_singularLabel পাওয়া যায়নি',
                            message: 'এখনো কোন $_singularLabel যুক্ত করা হয়নি',
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<SectorBloc>().add(SectorFetchRequested(widget.type));
                        },
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: sectors.length,
                          itemBuilder: (context, index) {
                            final sector = sectors[index];
                            return SectorCard(
                              sector: sector,
                              onEdit: () => _onEditSector(sector),
                              onDelete: () => _onDeleteSector(sector),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 3,
          onPressed: _onAddSector,
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedAdd01,
            size: 24,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
