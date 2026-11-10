class ExceptionFormatter {
  static String format(dynamic error) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    final regex = RegExp(r'\s*\(and \d+ more errors?\)', caseSensitive: false);
    message = message.replaceAll(regex, '').trim();
    return message;
  }
}
