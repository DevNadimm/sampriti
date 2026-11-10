import 'package:sampriti/core/utils/enums/error_type.dart';

class ApiException implements Exception {
  final String? title;
  final String message;
  final ErrorType type;

  ApiException({this.title, required this.message, this.type = ErrorType.unknown});

  @override
  String toString() => message;
}
