import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/selectable_chip.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/features/reports/data/models/report_period.dart';

/// Horizontal preset chips (এই মাস · গত মাস · এই বছর · সব সময় · কাস্টম) with the chosen range below.
class PeriodFilterBar extends StatelessWidget {
  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChanged;

  const PeriodFilterBar({super.key, required this.value, required this.onChanged});

  static const List<ReportPeriodPreset> _presets = [
    ReportPeriodPreset.thisMonth,
    ReportPeriodPreset.lastMonth,
    ReportPeriodPreset.thisYear,
    ReportPeriodPreset.all,
    ReportPeriodPreset.custom,
  ];

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final initial = (value.from.isNotEmpty && value.to.isNotEmpty)
        ? DateTimeRange(start: DateTime.parse(value.from), end: DateTime.parse(value.to))
        : null;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (range != null) {
      onChanged(ReportPeriod.custom(range.start, range.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final p = _presets[i];
              return SelectableChip(
                label: ReportPeriod.presetTitle(p),
                isSelected: value.preset == p,
                height: 34,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                onSelected: () {
                  if (p == ReportPeriodPreset.custom) {
                    _pickCustom(context);
                  } else {
                    onChanged(ReportPeriod.preset(p));
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.label,
          style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
