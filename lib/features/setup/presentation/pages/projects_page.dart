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
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/presentation/bloc/project_bloc.dart';
import 'package:sampriti/features/setup/presentation/pages/add_edit_project_page.dart';
import 'package:sampriti/features/setup/presentation/widgets/project_card.dart';

class ProjectsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const ProjectsPage());

  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(ProjectFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddProject() {
    Navigator.push(context, AddEditProjectPage.route());
  }

  void _onEditProject(ProjectModel project) {
    Navigator.push(context, AddEditProjectPage.route(project: project));
  }

  void _onDeleteProject(ProjectModel project) {
    AppConfirmationDialog.show(
      context,
      title: 'প্রকল্প মুছে ফেলুন',
      message: 'আপনি কি নিশ্চিত যে "${project.name}" প্রকল্পটি মুছে ফেলতে চান?',
      confirmText: 'মুছে ফেলুন',
      isDestructive: true,
      onConfirm: () {
        context.read<ProjectBloc>().add(ProjectDeleteRequested(project.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectActionSuccess) {
          AppNotifier.showSuccessSnackBar(context, state.message);
        } else if (state is ProjectFailure) {
          AppNotifier.showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            'ইনভেস্টমেন্ট প্রকল্পসমূহ',
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
                  hintText: 'প্রকল্প খুঁজুন (নাম, বিবরণ বা সদস্য নং)...',
                  onChanged: (val) {
                    context.read<ProjectBloc>().add(ProjectSearchRequested(val));
                  },
                ),
              ),

              // Content Area
              Expanded(
                child: BlocBuilder<ProjectBloc, ProjectState>(
                  builder: (context, state) {
                    if (state is ProjectLoading || state is ProjectInitial) {
                      return const ShimmerList(
                        itemCount: 5,
                        itemHeight: 140,
                      );
                    }

                    if (state is ProjectFailure && state is! ProjectLoaded) {
                      return ErrorStateWidget(
                        message: state.message,
                        onRetry: () => context.read<ProjectBloc>().add(ProjectFetchRequested()),
                      );
                    }

                    if (state is ProjectLoaded) {
                      final projects = state.filteredProjects;

                      if (projects.isEmpty) {
                        return const Center(
                          child: EmptyStateWidget(
                            title: 'কোন প্রকল্প নেই',
                            message: 'এখনো কোন ইনভেস্টমেন্ট প্রজেক্ট তৈরি করা হয়নি',
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ProjectBloc>().add(ProjectFetchRequested());
                        },
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            return ProjectCard(
                              project: project,
                              onEdit: () => _onEditProject(project),
                              onDelete: () => _onDeleteProject(project),
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
          onPressed: _onAddProject,
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
