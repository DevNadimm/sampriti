import 'package:flutter_test/flutter_test.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/models/nominee_model.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

void main() {
  group('DateFormatter UI vs DB Tests', () {
    test('converts DB yyyy-MM-dd to UI dd/MM/yyyy format (02/02/2026)', () {
      expect(DateFormatter.ddMMyyyy('2026-02-02'), '02/02/2026');
      expect(DateFormatter.toUi('2026-02-02'), '02/02/2026');
      expect(DateFormatter.ddMMyyyy('1995-12-25'), '25/12/1995');
      expect(DateFormatter.ddMMyyyy('2026-11-10'), '10/11/2026');
    });

    test('converts UI dd/MM/yyyy to DB yyyy-MM-dd format', () {
      expect(DateFormatter.yyyyMMdd('02/02/2026'), '2026-02-02');
      expect(DateFormatter.toDb('02/02/2026'), '2026-02-02');
      expect(DateFormatter.yyyyMMdd('25/12/1995'), '1995-12-25');
      expect(DateFormatter.yyyyMMdd('10/11/2026'), '2026-11-10');
    });

    test('handles DateTime objects correctly', () {
      final dt = DateTime(2026, 2, 2);
      expect(DateFormatter.ddMMyyyy(dt), '02/02/2026');
      expect(DateFormatter.yyyyMMdd(dt), '2026-02-02');
    });

    test('handles empty or null safely', () {
      expect(DateFormatter.ddMMyyyy(''), '');
      expect(DateFormatter.ddMMyyyy(null), '');
      expect(DateFormatter.ddMMyyyy('—'), '');
      expect(DateFormatter.yyyyMMdd(''), '');
      expect(DateFormatter.yyyyMMdd(null), '');
      expect(DateFormatter.yyyyMMdd('—'), '');
    });
  });

  group('Model Date Consistency Tests', () {
    test('TransactionModel stores in DB as yyyy-MM-dd and displays in UI as dd/MM/yyyy', () {
      // Created with UI format input
      final trxFromUi = TransactionModel(
        id: 't1',
        vno: 'V-0001',
        date: '02/02/2026',
        type: 'share_in',
        amount: 5000,
      );

      // In UI
      expect(trxFromUi.uiDate, '02/02/2026');

      // In DB (toMap)
      final map = trxFromUi.toMap();
      expect(map['date'], '2026-02-02');

      // Restored from DB (fromMap)
      final restored = TransactionModel.fromMap(map);
      expect(restored.date, '2026-02-02'); // normalized DB format
      expect(restored.uiDate, '02/02/2026'); // UI format
    });

    test('MemberModel stores birth in DB as yyyy-MM-dd and displays in UI as dd/MM/yyyy', () {
      final member = MemberModel(
        no: 'S101',
        nameBn: 'আব্দুল করিম',
        birth: '02/02/2026',
      );

      // In UI
      expect(member.uiBirth, '02/02/2026');

      // In DB (toMap)
      final map = member.toMap();
      expect(map['birth'], '2026-02-02');

      // Restored from DB (fromMap)
      final restored = MemberModel.fromMap(map);
      expect(restored.birth, '2026-02-02');
      expect(restored.uiBirth, '02/02/2026');
    });

    test('NomineeModel stores birth in DB as yyyy-MM-dd and displays in UI as dd/MM/yyyy', () {
      final nominee = NomineeModel(
        name: 'রাশেদ',
        birth: '02/02/2026',
      );

      // In UI
      expect(nominee.uiBirth, '02/02/2026');

      // In DB (toMap)
      final map = nominee.toMap();
      expect(map['birth'], '2026-02-02');

      // Restored from DB (fromMap)
      final restored = NomineeModel.fromMap(map);
      expect(restored.birth, '2026-02-02');
      expect(restored.uiBirth, '02/02/2026');
    });
  });
}
