import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';
import 'package:sampriti/features/transactions/data/models/legacy_type_map.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

/// One-time cleanup: rewrites old `type`-based vouchers into the structural schema.
/// Safe to run repeatedly. Until it runs, TransactionModel.fromMap already reads old docs correctly.
class TransactionsMigrationRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const int _targetSchema = 2;
  static const int _batchSize = 400;

  /// Profit payouts saved in bank mode before the bank picker existed have an
  /// empty `acct`. If the org has exactly one active bank account, that is the
  /// only account those payouts can belong to, so we fill it in.
  /// With several banks the right account cannot be inferred, so nothing is
  /// changed and the count is logged for manual review. Idempotent.
  static Future<void> _backfillBankPayoutAccounts() async {
    try {
      final banks = await _firestore.collection('bank_accounts').get();
      final active = banks.docs.where((d) => (d.data()['isActive'] as bool?) ?? true).toList();

      final snap = await _firestore
          .collection('transactions')
          .where('kind', isEqualTo: 'profit_payout')
          .where('mode', isEqualTo: 'bank')
          .where('acct', isEqualTo: '')
          .get();
      if (snap.docs.isEmpty) return;

      if (active.length != 1) {
        debugPrint('Bank payout backfill skipped: ${snap.docs.length} payouts need manual account assignment (${active.length} active banks).');
        return;
      }

      final bankId = active.first.id;
      for (var i = 0; i < snap.docs.length; i += _batchSize) {
        final end = (i + _batchSize) < snap.docs.length ? i + _batchSize : snap.docs.length;
        final batch = _firestore.batch();
        for (final d in snap.docs.sublist(i, end)) {
          batch.update(d.reference, {'acct': bankId});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Bank payout backfill failed: $e');
    }
  }

  /// Admin only. Silent on failure, never throws.
  static Future<void> runIfNeeded() async {
    try {
      final role = await AppPreferences.getUserRole();
      if (role == 'shareholder') return;

      await _backfillBankPayoutAccounts();

      final flag = await _firestore.collection('settings').doc('migrations').get();
      final current = (flag.data()?['trxSchema'] as num?)?.toInt() ?? 1;
      if (current >= _targetSchema) return;

      // Warm projects and system khats so `project ← inst` and system ids resolve.
      await SetupRepo.getProjects();
      await SetupRepo.getSectors(SectorType.income);
      await SetupRepo.getSectors(SectorType.expense);

      final snap = await _firestore.collection('transactions').get();
      final legacyDocs = snap.docs.where((d) {
        final dir = (d.data()['dir'] as String?)?.trim() ?? '';
        return dir.isEmpty;
      }).toList();

      // Seed only the legacy khats actually needed by this data.
      final needed = <String>{};
      for (final d in legacyDocs) {
        needed.add(LegacyTypeMap.resolve((d.data()['type'] as String?) ?? '').sectorId);
      }
      final seeds = [
        ...SectorModel.getSeededLegacySectors(SectorType.income),
        ...SectorModel.getSeededLegacySectors(SectorType.expense),
      ];
      for (final s in seeds) {
        if (needed.contains(s.id)) {
          await SetupRepo.seedLegacySector(s);
        }
      }

      // Rewrite old docs in chunks.
      for (var i = 0; i < legacyDocs.length; i += _batchSize) {
        final batch = _firestore.batch();
        final end = (i + _batchSize) < legacyDocs.length ? i + _batchSize : legacyDocs.length;
        for (final d in legacyDocs.sublist(i, end)) {
          final data = d.data();
          final legacyType = (data['type'] as String?) ?? '';
          final resolved = TransactionModel.fromMap(data, d.id);

          // Fold old free-text category into note so nothing is lost.
          final oldCat = (data['cat'] as String?)?.trim() ?? '';
          var note = resolved.note;
          if (oldCat.isNotEmpty) {
            note = note.isEmpty ? oldCat : '$oldCat | $note';
          }

          batch.update(d.reference, {
            'dir': resolved.dir,
            'sectorId': resolved.sectorId,
            'sectorKey': resolved.sectorKey,
            'sectorName': resolved.sectorName,
            'project': resolved.project,
            'kind': resolved.kind,
            'note': note,
            'legacyType': legacyType,
            'schema': _targetSchema,
            'type': FieldValue.delete(),
            'plan': FieldValue.delete(),
            'cat': FieldValue.delete(),
          });
        }
        await batch.commit();
      }

      // Flag last, so a partial run is retried next time.
      await _firestore.collection('settings').doc('migrations').set(
        {
          'trxSchema': _targetSchema,
          'migratedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Transaction migration skipped: $e');
    }
  }
}
