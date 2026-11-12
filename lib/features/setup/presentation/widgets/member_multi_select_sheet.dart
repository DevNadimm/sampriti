import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';

class MemberMultiSelectSheet extends StatefulWidget {
  final List<String> initialSelectedMemberNos;
  final ValueChanged<List<String>> onConfirmed;

  const MemberMultiSelectSheet({
    super.key,
    required this.initialSelectedMemberNos,
    required this.onConfirmed,
  });

  static Future<List<String>?> show({
    required BuildContext context,
    required List<String> initialSelectedMemberNos,
  }) async {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberMultiSelectSheet(
        initialSelectedMemberNos: initialSelectedMemberNos,
        onConfirmed: (selected) => Navigator.pop(context, selected),
      ),
    );
  }

  @override
  State<MemberMultiSelectSheet> createState() => _MemberMultiSelectSheetState();
}

class _MemberMultiSelectSheetState extends State<MemberMultiSelectSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<MemberModel> _allMembers = [];
  List<MemberModel> _filteredMembers = [];
  late final Set<String> _selectedNos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedNos = Set<String>.from(widget.initialSelectedMemberNos);
    _loadMembers();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadMembers() async {
    try {
      final members = await MembersRepo.getMembers(bypassSecurity: true);
      if (mounted) {
        setState(() {
          _allMembers = members;
          _filteredMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _allMembers;
      } else {
        _filteredMembers = _allMembers.where((m) {
          return m.no.toLowerCase().contains(query) ||
              m.nameBn.toLowerCase().contains(query) ||
              m.nameEn.toLowerCase().contains(query) ||
              m.mobile.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedNos.length == _allMembers.length) {
        _selectedNos.clear();
      } else {
        _selectedNos.clear();
        _selectedNos.addAll(_allMembers.map((m) => m.no));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final allSelected = _allMembers.isNotEmpty && _selectedNos.length == _allMembers.length;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'প্রকল্পের সদস্য নির্বাচন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'শেয়ারহোল্ডারদের মধ্য থেকে প্রজেক্ট মেম্বার নির্বাচন করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _allMembers.isEmpty ? null : _toggleSelectAll,
                  child: Text(
                    allSelected ? 'সব বাতিল' : 'সবাইকে নির্বাচন',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextField.search(
              controller: _searchController,
              hintText: 'শেয়ারহোল্ডার খুঁজুন (নাম বা শেয়ার নং)...',
            ),
          ),
          const SizedBox(height: 10),

          // Member List
          Expanded(
            child: _isLoading
                ? const Center(child: Loader())
                : _filteredMembers.isEmpty
                    ? const EmptyStateWidget(
                        title: 'কোন সদস্য পাওয়া যায়নি',
                        message: 'অনুসন্ধানের সাথে মিল রেখে কোনো শেয়ারহোল্ডার নেই',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: _filteredMembers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final isChecked = _selectedNos.contains(member.no);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  _selectedNos.remove(member.no);
                                } else {
                                  _selectedNos.add(member.no);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppColors.primary.withValues(alpha: 0.05)
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isChecked ? AppColors.primary : AppColors.inputBorder,
                                  width: isChecked ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  MemberAvatar(
                                    photo: member.photo,
                                    fallbackText: member.no,
                                    size: 40,
                                    isCircle: true,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                member.no,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                member.displayName,
                                                style: GoogleFonts.notoSansBengali(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'শেয়ার: ${member.shares} টি • মোবাইল: ${member.mobile.isNotEmpty ? member.mobile : "—"}',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedNos.add(member.no);
                                        } else {
                                          _selectedNos.remove(member.no);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Confirmation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SpringButton(
              width: double.infinity,
              onPressed: () {
                widget.onConfirmed(_selectedNos.toList());
              },
              child: Text(
                'নির্বাচন নিশ্চিত করুন (${_selectedNos.length} জন)',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
