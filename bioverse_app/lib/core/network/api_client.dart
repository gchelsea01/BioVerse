import 'dart:async';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio: attaches the bearer token, refreshes it once on
/// 401, and converts every failure into [ApiException].
class ApiClient {
  ApiClient(this.tokens, {String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.accessToken;
        if (token != null && options.extra['auth'] != false) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final req = error.requestOptions;
        final canRetry = error.response?.statusCode == 401 &&
            req.extra['auth'] != false &&
            req.extra['retried'] != true &&
            tokens.refreshToken != null;
        if (!canRetry) return handler.next(error);

        final refreshed = await _refresh();
        if (!refreshed) {
          onSessionExpired?.call();
          return handler.next(error);
        }
        try {
          req.extra['retried'] = true;
          req.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          handler.resolve(await dio.fetch(req));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ));
  }

  final Dio dio;
  final TokenStorage tokens;

  /// Called when the refresh token is rejected; the app returns to login.
  void Function()? onSessionExpired;

  static final _uuid = const Uuid();
  static String idempotencyKey() => _uuid.v4();

  Future<bool> _refresh() async {
    try {
      final res = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
        '/app/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );
      final data = res.data as Map;
      await tokens.save(
        access: data['access_token'] as String,
        refresh: (data['refresh_token'] ?? tokens.refreshToken) as String,
      );
      return true;
    } catch (_) {
      await tokens.clear();
      return false;
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send(() => dio.get(path, queryParameters: _clean(query), options: Options(extra: {'auth': auth})));

  Future<T> post<T>(String path, {Object? body, Map<String, String>? headers, bool auth = true}) =>
      _send(() => dio.post(path, data: body ?? {}, options: Options(headers: headers, extra: {'auth': auth})));

  Future<T> patch<T>(String path, {Object? body}) => _send(() => dio.patch(path, data: body ?? {}));

  /// Uploads raw bytes to a presigned URL (S3/MinIO), outside the API base URL.
  Future<void> putBytes(String url, List<int> bytes, Map<String, String> headers) async {
    try {
      await Dio().put(
        url,
        data: Stream.fromIterable([bytes]),
        options: Options(headers: {...headers, Headers.contentLengthHeader: bytes.length}),
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<T> _send<T>(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data as T;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? q) =>
      q == null ? null : (Map.of(q)..removeWhere((_, v) => v == null || v == ''));
}
