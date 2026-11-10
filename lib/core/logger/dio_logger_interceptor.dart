import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class DioLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln('┌─────────────── ➡️  REQUEST ───────────────')
        ..writeln('│ METHOD  : ${options.method}')
        ..writeln('│ URL     : ${options.uri}')
        ..writeln('│ HEADERS : ${options.headers}');

      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('│ QUERY   : ${options.queryParameters}');
      }
      if (options.data != null) {
        buffer.writeln('│ BODY    : ${options.data}');
      }

      buffer.write('└────────────────────────────────────────');
      AppLogger.i(buffer.toString());
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.i(
        '┌─────────────── ✅  RESPONSE ──────────────\n'
        '│ STATUS : ${response.statusCode}\n'
        '│ URL    : ${response.requestOptions.uri}\n'
        '│ DATA   : ${response.data}\n'
        '└────────────────────────────────────────',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '┌─────────────── ❌  ERROR ─────────────────\n'
      '│ URL     : ${err.requestOptions.uri}\n'
      '│ STATUS  : ${err.response?.statusCode}\n'
      '│ MESSAGE : ${err.message}\n'
      '│ DATA    : ${err.response?.data}\n'
      '└────────────────────────────────────────',
      err,
      err.stackTrace,
    );

    handler.next(err);
  }
}
