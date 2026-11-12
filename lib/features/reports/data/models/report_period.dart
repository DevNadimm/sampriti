enum ReportPeriodPreset { thisMonth, lastMonth, thisYear, all, custom }

const List<String> kBnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

/// Converts ASCII digits to Bangla digits.
String bnDigits(String s) {
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final d = int.tryParse(ch);
    b.write(d != null && ch.codeUnitAt(0) < 128 ? bn[d] : ch);
  }
  return b.toString();
}

/// "2026-11" → "নভেম্বর ২০২৬"
String bnMonthLabel(String yearMonth) {
  final parts = yearMonth.split('-');
  if (parts.length < 2) return yearMonth;
  final m = int.tryParse(parts[1]) ?? 0;
  if (m < 1 || m > 12) return yearMonth;
  return '${kBnMonths[m - 1]} ${bnDigits(parts[0])}';
}

/// A reporting window. Dates are DB format (YYYY-MM-DD); '' means open-ended.
class ReportPeriod {
  final ReportPeriodPreset preset;
  final String from;
  final String to;

  const ReportPeriod({required this.preset, this.from = '', this.to = ''});

  static String dbDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  factory ReportPeriod.preset(ReportPeriodPreset p, {DateTime? now}) {
    final n = now ?? DateTime.now();
    switch (p) {
      case ReportPeriodPreset.thisMonth:
        return ReportPeriod(
          preset: p,
          from: dbDate(DateTime(n.year, n.month, 1)),
          to: dbDate(DateTime(n.year, n.month + 1, 0)),
        );
      case ReportPeriodPreset.lastMonth:
        return ReportPeriod(
          preset: p,
          from: dbDate(DateTime(n.year, n.month - 1, 1)),
          to: dbDate(DateTime(n.year, n.month, 0)),
        );
      case ReportPeriodPreset.thisYear:
        return ReportPeriod(
          preset: p,
          from: dbDate(DateTime(n.year, 1, 1)),
          to: dbDate(DateTime(n.year, 12, 31)),
        );
      case ReportPeriodPreset.all:
      case ReportPeriodPreset.custom:
        return ReportPeriod(preset: ReportPeriodPreset.all);
    }
  }

  factory ReportPeriod.custom(DateTime from, DateTime to) => ReportPeriod(
        preset: ReportPeriodPreset.custom,
        from: dbDate(from),
        to: dbDate(to),
      );

  bool get isAll => from.isEmpty && to.isEmpty;

  /// True when [date] (YYYY-MM-DD) falls inside the window.
  bool contains(String date) =>
      (from.isEmpty || date.compareTo(from) >= 0) && (to.isEmpty || date.compareTo(to) <= 0);

  /// True when [date] is before the window starts (counts toward opening balance).
  bool isBefore(String date) => from.isNotEmpty && date.compareTo(from) < 0;

  /// True when [date] is after the window ends (ignored entirely).
  bool isAfter(String date) => to.isNotEmpty && date.compareTo(to) > 0;

  static String presetTitle(ReportPeriodPreset p) {
    switch (p) {
      case ReportPeriodPreset.thisMonth:
        return 'এই মাস';
      case ReportPeriodPreset.lastMonth:
        return 'গত মাস';
      case ReportPeriodPreset.thisYear:
        return 'এই বছর';
      case ReportPeriodPreset.all:
        return 'সব সময়';
      case ReportPeriodPreset.custom:
        return 'কাস্টম';
    }
  }

  String _uiDate(String db) {
    final p = db.split('-');
    if (p.length != 3) return db;
    return bnDigits('${p[2]}/${p[1]}/${p[0]}');
  }

  /// Human label: "নভেম্বর ২০২৬", "বছর ২০২৬", "সব সময়", "০১/০১/২০২৬ – ৩১/১০/২০২৬"
  String get label {
    if (isAll) return 'সব সময়';
    switch (preset) {
      case ReportPeriodPreset.thisMonth:
      case ReportPeriodPreset.lastMonth:
        return bnMonthLabel(from.substring(0, 7));
      case ReportPeriodPreset.thisYear:
        return 'বছর ${bnDigits(from.substring(0, 4))}';
      default:
        final f = from.isEmpty ? 'শুরু' : _uiDate(from);
        final t = to.isEmpty ? 'আজ' : _uiDate(to);
        return '$f – $t';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.preset == preset && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(preset, from, to);
}
