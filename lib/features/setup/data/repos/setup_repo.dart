import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';

class SetupRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _projectsCollection = 'projects';
  static const String _incomeSectorsCollection = 'income_sectors';
  static const String _expenseSectorsCollection = 'expense_sectors';

  // ==================== PROJECTS ====================

  /// Fetch all projects sorted by start date / created date descending
  static Future<List<ProjectModel>> getProjects() async {
    try {
      final snap = await _firestore.collection(_projectsCollection).get();
      List<ProjectModel> list = snap.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();

      // Self-healing: If projects collection is empty, auto-seed from institutions
      if (list.isEmpty) {
        try {
          final instSnap = await _firestore.collection('institutions').get();
          if (instSnap.docs.isNotEmpty) {
            final batch = _firestore.batch();
            final now = DateTime.now().toIso8601String();
            for (final doc in instSnap.docs) {
              final data = doc.data();
              final rawName = (data['name'] as String?) ?? '';
              final name = rawName.contains('স্কুল') ? rawName.replaceAll('স্কুল', 'স্কু\u200Cল') : rawName;
              if (name.isNotEmpty) {
                final proj = ProjectModel(
                  id: doc.id,
                  name: name,
                  description: '$name প্রতিষ্ঠান ও ইনভেস্টমেন্ট প্রকল্প',
                  startDate: '2026-01-01',
                  status: 'active',
                  createdAt: now,
                  updatedAt: now,
                );
                batch.set(_firestore.collection(_projectsCollection).doc(doc.id), proj.toMap());
                list.add(proj);
              }
            }
            await batch.commit();
          }
        } catch (_) {}
      }

      // Sort: active first, then date descending
      list.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.startDate.compareTo(a.startDate);
      });

      return list;
    } catch (e) {
      throw ApiException(
        message: 'প্রকল্প তালিকা লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।',
      );
    }
  }

  /// Add or update a project (Admin Only)
  static Future<void> saveProject(ProjectModel project) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'প্রকল্প পরিবর্তনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      if (project.id.isEmpty) {
        // Create new
        await _firestore.collection(_projectsCollection).add(project.toMap());
      } else {
        // Update existing
        await _firestore
            .collection(_projectsCollection)
            .doc(project.id)
            .set(project.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      throw ApiException(message: 'প্রকল্প তথ্য সংরক্ষণ করা সম্ভব হয়নি।');
    }
  }

  /// Delete a project (Admin Only)
  static Future<void> deleteProject(String id) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'প্রকল্প মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      await _firestore.collection(_projectsCollection).doc(id).delete();
    } catch (e) {
      throw ApiException(message: 'প্রকল্প মুছে ফেলা সম্ভব হয়নি।');
    }
  }

  // ==================== SECTORS (INCOME / EXPENSE) ====================

  static String _getSectorCollection(SectorType type) {
    return type == SectorType.income ? _incomeSectorsCollection : _expenseSectorsCollection;
  }

  /// Fetch sectors for either Income or Expense with self-healing auto-provisioning
  static Future<List<SectorModel>> getSectors(SectorType type) async {
    try {
      final coll = _getSectorCollection(type);
      final snap = await _firestore.collection(coll).get();

      final requiredSystemSectors = SectorModel.getSystemSectors(type);
      final existingDocIds = snap.docs.map((d) => d.id).toSet();
      final existingKeys = snap.docs.map((d) {
        final data = d.data();
        return (data['key'] ?? '').toString().trim();
      }).where((k) => k.isNotEmpty && k != SectorModel.keyCustom).toSet();

      // Check which required system sectors are missing
      final missingSystemSectors = <SectorModel>[];
      for (final sysSec in requiredSystemSectors) {
        if (!existingDocIds.contains(sysSec.id) && !existingKeys.contains(sysSec.key)) {
          missingSystemSectors.add(sysSec);
        }
      }

      // Self-healing: if any system sector is missing, auto-provision in Firestore
      if (missingSystemSectors.isNotEmpty) {
        final batch = _firestore.batch();
        for (final missing in missingSystemSectors) {
          final docRef = _firestore.collection(coll).doc(missing.id);
          batch.set(docRef, missing.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      }

      final list = <SectorModel>[];
      final seenIds = <String>{};

      for (final doc in snap.docs) {
        final sector = SectorModel.fromFirestore(doc, type);
        list.add(sector);
        seenIds.add(sector.id);
      }

      // Ensure newly provisioned ones are immediately present in the result
      for (final missing in missingSystemSectors) {
        if (!seenIds.contains(missing.id)) {
          list.add(missing);
        }
      }

      // Sort: System sectors first, then custom sectors alphabetically by name
      list.sort((a, b) {
        if (a.isSystem && !b.isSystem) return -1;
        if (!a.isSystem && b.isSystem) return 1;
        return a.name.compareTo(b.name);
      });

      return list;
    } catch (e) {
      final title = type == SectorType.income ? 'আয়ের খাত' : 'ব্যয়ের খাত';
      throw ApiException(
        message: '$title তালিকা লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।',
      );
    }
  }

  /// Add or update a sector (Admin Only, System Key Protected)
  static Future<void> saveSector(SectorModel sector) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'খাত পরিবর্তনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      final coll = _getSectorCollection(sector.type);
      if (sector.id.isEmpty) {
        // User created custom sector: key is 'custom', isSystem is false
        final customSector = sector.copyWith(
          key: SectorModel.keyCustom,
          isSystem: false,
        );
        await _firestore.collection(coll).add(customSector.toMap());
      } else {
        // Updating existing sector
        if (sector.isSystem || sector.id.startsWith('sys_')) {
          // Lock system parameters so internal keys remain intact
          final lockedSector = sector.copyWith(
            isSystem: true,
            key: sector.key.isNotEmpty && sector.key != SectorModel.keyCustom
                ? sector.key
                : (sector.id == SectorModel.idIncShareholder || sector.id == SectorModel.idExpShareholder
                    ? SectorModel.keyShareholder
                    : (sector.id == SectorModel.idIncProkolpo || sector.id == SectorModel.idExpProkolpo
                        ? SectorModel.keyProkolpo
                        : SectorModel.keyDonation)),
          );
          await _firestore.collection(coll).doc(sector.id).set(lockedSector.toMap(), SetOptions(merge: true));
        } else {
          final customSector = sector.copyWith(
            key: SectorModel.keyCustom,
            isSystem: false,
          );
          await _firestore.collection(coll).doc(sector.id).set(customSector.toMap(), SetOptions(merge: true));
        }
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'খাতের তথ্য সংরক্ষণ ব্যর্থ হয়েছে।');
    }
  }

  /// Migration-only: create a legacy custom khat if it does not exist yet.
  /// Never overwrites, so admin edits survive re-runs.
  static Future<void> seedLegacySector(SectorModel sector) async {
    final coll = _getSectorCollection(sector.type);
    final ref = _firestore.collection(coll).doc(sector.id);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set(sector.toMap());
  }

  /// Delete a sector (Admin Only, System Sectors Protected)
  static Future<void> deleteSector(String id, SectorType type) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'খাত মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    // Protection Check 1: Fast ID check
    if (id.startsWith('sys_') ||
        id == SectorModel.idIncShareholder ||
        id == SectorModel.idIncProkolpo ||
        id == SectorModel.idExpShareholder ||
        id == SectorModel.idExpProkolpo ||
        id == SectorModel.idExpDonation) {
      throw ApiException(message: 'সিস্টেমের ডিফল্ট বা ফিক্সড খাত মুছে ফেলা সম্ভব নয়');
    }

    try {
      final coll = _getSectorCollection(type);
      final docSnap = await _firestore.collection(coll).doc(id).get();
      if (docSnap.exists) {
        final data = docSnap.data();
        if (data?['isSystem'] == true) {
          throw ApiException(message: 'সিস্টেমের ডিফল্ট বা ফিক্সড খাত মুছে ফেলা সম্ভব নয়');
        }
      }
      await _firestore.collection(coll).doc(id).delete();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'খাত মুছে ফেলা সম্ভব হয়নি।');
    }
  }
}
