import 'package:dio/dio.dart';
import '../errors/app_failure.dart';
import '../../utils/constants.dart';
import 'token_store.dart';

class ApiClient {
  final Dio dio;
  final TokenStore tokens;
  final String refreshPath;
  Future<void>? _refreshing;
  void Function()? onExpired;
  void Function(String code)? onSubscriptionRequired;
  ApiClient(
    this.dio,
    this.tokens, {
    this.refreshPath = ApiConstants.refreshToken,
  });
  Future<void> _refresh() async {
    if (tokens.refreshToken == null) {
      throw const AppFailure('Silakan masuk kembali', code: 'UNAUTHENTICATED');
    }
    final generation = tokens.sessionGeneration;
    final response = await dio.post(
      refreshPath,
      data: {'refreshToken': tokens.refreshToken},
    );
    final data = Map<String, dynamic>.from(response.data['data']);
    if (tokens.sessionGeneration != generation) {
      throw const AppFailure(
        'Sesi akun berubah. Silakan ulangi dari akun yang sedang aktif.',
        code: 'SESSION_CHANGED',
      );
    }
    await tokens.save(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    bool authenticated = true,
    int? expectedSessionGeneration,
    FormData Function()? multipart,
  }) async {
    final requestSession = tokens.sessionGeneration;
    try {
      Future<Response<dynamic>> send() {
        if (expectedSessionGeneration != null &&
            tokens.sessionGeneration != expectedSessionGeneration) {
          throw const AppFailure(
            'Sesi akun berubah. Verifikasi ulang akun yang sedang aktif.',
            code: 'SESSION_CHANGED',
          );
        }
        return dio.request(
          path,
          data: multipart?.call() ?? data,
          queryParameters: query,
          options: Options(
            method: method,
            contentType: multipart == null
                ? null
                : Headers.multipartFormDataContentType,
            headers: authenticated && tokens.accessToken != null
                ? {'Authorization': 'Bearer ${tokens.accessToken}'}
                : {},
          ),
        );
      }

      Response<dynamic> response;
      try {
        response = await send();
      } on DioException catch (error) {
        if (error.response?.statusCode != 401 || !authenticated) rethrow;
        if (expectedSessionGeneration != null &&
            tokens.sessionGeneration != expectedSessionGeneration) {
          throw const AppFailure(
            'Sesi akun berubah. Verifikasi ulang akun yang sedang aktif.',
            code: 'SESSION_CHANGED',
          );
        }
        try {
          _refreshing ??= _refresh();
          await _refreshing;
        } finally {
          _refreshing = null;
        }
        response = await send();
      }
      return response.data['data'];
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 &&
          authenticated &&
          tokens.sessionGeneration == requestSession) {
        await tokens.clear();
        onExpired?.call();
      }
      final body = error.response?.data;
      final failure = body is Map ? body['error'] : null;
      final message = failure is Map ? failure['message'] : null;
      if (status == 402 && authenticated && failure is Map) {
        onSubscriptionRequired?.call(
          failure['code'] as String? ?? 'SUBSCRIPTION_REQUIRED',
        );
      }
      throw AppFailure(
        message is List
            ? message.join('\n')
            : message is String
            ? message
            : 'Server tidak dapat dihubungi. Periksa koneksi dan coba lagi.',
        code: failure is Map
            ? (failure['code'] as String? ?? 'NETWORK')
            : 'NETWORK',
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async =>
      Map<String, dynamic>.from(await request('GET', path, query: query));

  Future<Map<String, dynamic>> uploadFile(
    String path,
    List<int> bytes, {
    required String filename,
    required String mimeType,
    required int expectedSessionGeneration,
  }) async => Map<String, dynamic>.from(
    await request(
      'POST',
      path,
      expectedSessionGeneration: expectedSessionGeneration,
      // A 401 retry needs a fresh body; a finalized FormData cannot be reused.
      multipart: () => FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      }),
    ),
  );
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data, {
    bool authenticated = true,
  }) async => Map<String, dynamic>.from(
    await request('POST', path, data: data, authenticated: authenticated),
  );
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data,
  ) async =>
      Map<String, dynamic>.from(await request('PATCH', path, data: data));

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
    int? expectedSessionGeneration,
  }) async => Map<String, dynamic>.from(
    await request(
      'DELETE',
      path,
      data: data,
      expectedSessionGeneration: expectedSessionGeneration,
    ),
  );
}
