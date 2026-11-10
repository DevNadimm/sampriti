import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';

class SearchableOptionPickerBottomSheet extends StatefulWidget {
  final List<String> options;
  final TextEditingController controller;
  final String title;
  final ValueChanged<String> onOptionPicked;

  const SearchableOptionPickerBottomSheet({
    super.key,
    required this.options,
    required this.controller,
    required this.title,
    required this.onOptionPicked,
  });

  @override
  State<SearchableOptionPickerBottomSheet> createState() => _SearchableOptionPickerBottomSheetState();
}

class _SearchableOptionPickerBottomSheetState extends State<SearchableOptionPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase().replaceAll('\u200C', '');
    setState(() {
      _filteredOptions = query.isEmpty
          ? widget.options
          : widget.options.where((option) {
              final clean = option.toLowerCase().replaceAll('\u200C', '');
              return clean.contains(query);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.87),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.notoSansBengali(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: _filteredOptions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _searchController.text.isNotEmpty
                          ? EmptyStateWidget(
                              isCenter: false,
                              icon: Image.asset(
                                Assets.noContent,
                                height: 90,
                                width: 90,
                              ),
                              title: 'কোনো ফলাফল পাওয়া যায়নি',
                              message: '"${_searchController.text}" এর সাথে মিলে এমন কিছু পাওয়া যায়নি। সঠিক বানান দিয়ে খুঁজুন।',
                            )
                          : EmptyStateWidget(
                              isCenter: false,
                              icon: Image.asset(
                                Assets.noContent,
                                height: 90,
                                width: 90,
                              ),
                              title: 'কোনো অপশন পাওয়া যায়নি',
                              message: 'এই মুহূর্তে কোনো আইটেম পাওয়া যায়নি।',
                            ),
                    )
                  : ListView.separated(
                      shrinkWrap: false,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      itemCount: _filteredOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _filteredOptions[index];
                        final isSelected = widget.controller.text == item;

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => widget.onOptionPicked(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.inputBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSansBengali(
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "খুঁজুন (Search)...",
        hintStyle: GoogleFonts.notoSansBengali(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () => _searchController.clear(),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.inputBorder, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.inputBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
