import 'package:flutter_test/flutter_test.dart';
import 'package:sampriti/features/members/data/models/nominee_model.dart';

void main() {
  group('NomineeModel Tests', () {
    test('creates and converts to/from Map correctly', () {
      final nominee = NomineeModel(
        name: 'মোছাঃ ফাতেমা বেগম',
        father: 'মোঃ রফিকুল ইসলাম',
        mother: 'নুরজাহান বেগম',
        relation: 'স্ত্রী',
        share: '100',
        mobile: '01711000000',
        nid: '19901234567890',
        birth: '1995-05-12',
        address: 'গ্রাম: রাধানগর, ডাকঘর: হরিপুর',
        photo: 'base64_encoded_photo_string',
      );

      final map = nominee.toMap();
      expect(map['name'], 'মোছাঃ ফাতেমা বেগম');
      expect(map['relation'], 'স্ত্রী');
      expect(map['share'], '100');
      expect(map['photo'], 'base64_encoded_photo_string');
      expect(map['father'], 'মোঃ রফিকুল ইসলাম');

      final fromMap = NomineeModel.fromMap(map);
      expect(fromMap.name, nominee.name);
      expect(fromMap.father, nominee.father);
      expect(fromMap.mother, nominee.mother);
      expect(fromMap.relation, nominee.relation);
      expect(fromMap.share, nominee.share);
      expect(fromMap.mobile, nominee.mobile);
      expect(fromMap.nid, nominee.nid);
      expect(fromMap.birth, nominee.birth);
      expect(fromMap.address, nominee.address);
      expect(fromMap.photo, nominee.photo);
    });

    test('handles missing optional fields safely', () {
      final fromEmptyMap = NomineeModel.fromMap({});
      expect(fromEmptyMap.name, '');
      expect(fromEmptyMap.share, '100');
      expect(fromEmptyMap.relation, '');
      expect(fromEmptyMap.photo, isNull);
    });
  });
}
