import 'package:sampriti/features/setup/data/models/sector_model.dart';

/// Maps the old 13 hardcoded `type` keys to the new structural fields.
/// Used by TransactionModel.fromMap (in-memory fallback) and by the migration.
class LegacyTypeMap {
  const LegacyTypeMap._();

  static LegacyResolved resolve(String legacyType) {
    switch (legacyType) {
      case 'share_in':
      case 'plan_dep':
        return const LegacyResolved(
          dir: 'in',
          sectorId: SectorModel.idIncShareholder,
          sectorKey: SectorModel.keyShareholder,
          sectorName: 'শেয়ারহোল্ডার',
        );
      case 'inst_income':
        return const LegacyResolved(
          dir: 'in',
          sectorId: SectorModel.idIncProkolpo,
          sectorKey: SectorModel.keyProkolpo,
          sectorName: 'প্রকল্প',
          projectFromInst: true,
        );
      case 'loan_return':
        return const LegacyResolved(
          dir: 'in',
          sectorId: 'legacy_inc_loan_return',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'লোন ফেরত প্রাপ্তি',
        );
      case 'donation':
        return const LegacyResolved(
          dir: 'in',
          sectorId: 'legacy_inc_donation_received',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'প্রাপ্ত ডোনেশন / অনুদান',
        );
      case 'inst_invest':
        return const LegacyResolved(
          dir: 'out',
          sectorId: SectorModel.idExpProkolpo,
          sectorKey: SectorModel.keyProkolpo,
          sectorName: 'প্রকল্প',
          projectFromInst: true,
        );
      case 'inst_loan':
        return const LegacyResolved(
          dir: 'out',
          sectorId: 'legacy_exp_inst_loan',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'প্রতিষ্ঠানকে লোন প্রদান',
        );
      case 'inst_subsidy':
        return const LegacyResolved(
          dir: 'out',
          sectorId: 'legacy_exp_subsidy',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'ভর্তুকি প্রদান',
        );
      case 'eid_bonus':
        return const LegacyResolved(
          dir: 'out',
          sectorId: 'legacy_exp_eid_bonus',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'ঈদ বোনাস প্রদান',
        );
      case 'expense':
        return const LegacyResolved(
          dir: 'out',
          sectorId: 'legacy_exp_general',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'অন্যান্য সাধারণ ব্যয়',
        );
      case 'payout':
        return const LegacyResolved(
          dir: 'out',
          sectorId: SectorModel.idExpShareholder,
          sectorKey: SectorModel.keyShareholder,
          sectorName: 'শেয়ারহোল্ডার',
          kind: 'profit_payout',
        );
      case 'bank_dep':
        return const LegacyResolved(
          dir: 'xfer',
          sectorKey: 'bank_transfer',
          sectorName: 'নগদ থেকে ব্যাংকে জমা',
          kind: 'bank_dep',
        );
      case 'bank_wd':
        return const LegacyResolved(
          dir: 'xfer',
          sectorKey: 'bank_transfer',
          sectorName: 'ব্যাংক থেকে নগদ উত্তোলন',
          kind: 'bank_wd',
        );
      default:
        return const LegacyResolved(
          dir: 'out',
          sectorKey: SectorModel.keyCustom,
          sectorName: 'অন্যান্য',
        );
    }
  }
}

class LegacyResolved {
  final String dir;
  final String sectorId;
  final String sectorKey;
  final String sectorName;
  final String kind;

  /// True when the old `inst` value is the project id (inst_income / inst_invest).
  final bool projectFromInst;

  const LegacyResolved({
    required this.dir,
    this.sectorId = '',
    required this.sectorKey,
    required this.sectorName,
    this.kind = '',
    this.projectFromInst = false,
  });
}
