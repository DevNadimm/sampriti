import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';

/// Meeting type keys stored in Firestore.
class MeetingType {
  static const String monthly = 'monthly';
  static const String emergency = 'emergency';
  static const String agm = 'agm';

  static String label(String key) {
    switch (key) {
      case emergency:
        return 'জরুরী সভা';
      case agm:
        return 'বার্ষিক সাধারণ সভা (AGM)';
      default:
        return 'মাসিক সভা';
    }
  }
}

/// One attendee row: name, designation, present flag, and signature text.
class MeetingAttendee {
  final String no;
  final String name;
  final String designation;
  final bool present;
  final String signature;

  const MeetingAttendee({
    required this.no,
    required this.name,
    this.designation = '',
    this.present = false,
    this.signature = '',
  });

  MeetingAttendee copyWith({String? designation, bool? present, String? signature}) => MeetingAttendee(
        no: no,
        name: name,
        designation: designation ?? this.designation,
        present: present ?? this.present,
        signature: signature ?? this.signature,
      );

  Map<String, dynamic> toMap() => {
        'no': no,
        'name': name,
        'designation': designation,
        'present': present,
        'signature': signature,
      };

  factory MeetingAttendee.fromMap(Map<String, dynamic> m) => MeetingAttendee(
        no: (m['no'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        designation: (m['designation'] as String?) ?? '',
        present: (m['present'] as bool?) ?? false,
        signature: (m['signature'] as String?) ?? '',
      );
}

/// A single meeting record. Each meeting is its own Firestore document (collection `meetings`).
class MeetingModel {
  final String id;
  final String type; // MeetingType key
  final String date; // DB: YYYY-MM-DD
  final String time; // free text, e.g. "সকাল ১০:০০ টা"
  final String place;
  final String presiding; // সভাপতিত্বে
  final String purpose; // সভার উদ্দেশ্য / কেন ডাকা হয়েছে
  final List<String> agendas; // সভার এজেন্ডা (ক্রমানুসারে)
  final List<String> agendaDecisions; // same length as agendas; '' = no decision
  final List<String> extraDecisions; // অতিরিক্ত সিদ্ধান্ত
  final List<MeetingAttendee> attendance;
  final String closing;
  final String createdAt;
  final String updatedAt;

  const MeetingModel({
    this.id = '',
    required this.type,
    required this.date,
    this.time = '',
    this.place = '',
    this.presiding = '',
    this.purpose = '',
    this.agendas = const [],
    this.agendaDecisions = const [],
    this.extraDecisions = const [],
    this.attendance = const [],
    this.closing = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get uiDate => DateFormatter.ddMMyyyy(date);
  String get typeLabel => MeetingType.label(type);
  int get presentCount => attendance.where((a) => a.present).length;

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'type': type,
      'date': DateFormatter.yyyyMMdd(date),
      'time': time.trim(),
      'place': place.trim(),
      'presiding': presiding.trim(),
      'purpose': purpose.trim(),
      'agendas': agendas,
      'agendaDecisions': agendaDecisions,
      'extraDecisions': extraDecisions,
      'attendance': attendance.map((a) => a.toMap()).toList(),
      'closing': closing.trim(),
      'createdAt': createdAt.isNotEmpty ? createdAt : now,
      'updatedAt': now,
      'schema': 1,
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> m, [String? docId]) {
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : <String>[];
    final att = m['attendance'];
    return MeetingModel(
      id: docId ?? (m['id'] as String?) ?? '',
      type: (m['type'] as String?) ?? MeetingType.monthly,
      date: DateFormatter.yyyyMMdd(m['date']),
      time: (m['time'] as String?) ?? '',
      place: (m['place'] as String?) ?? '',
      presiding: (m['presiding'] as String?) ?? '',
      purpose: (m['purpose'] as String?) ?? '',
      agendas: strList(m['agendas']),
      agendaDecisions: strList(m['agendaDecisions']),
      extraDecisions: strList(m['extraDecisions']),
      attendance: att is List
          ? att.whereType<Map>().map((e) => MeetingAttendee.fromMap(Map<String, dynamic>.from(e))).toList()
          : const [],
      closing: (m['closing'] as String?) ?? '',
      createdAt: (m['createdAt'] as String?) ?? '',
      updatedAt: (m['updatedAt'] as String?) ?? '',
    );
  }

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MeetingModel.fromMap(data, doc.id);
  }
}
