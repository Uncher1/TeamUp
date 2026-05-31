// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:dio/dio.dart';

import 'config.dart';
import 'storage.dart';

/// Wraps a configured [Dio] with a JWT interceptor.
///
/// The token is attached to every request from [TokenStorage]. On a 401 the
/// stored token is cleared and [onUnauthorized] is invoked so the app can
/// return to the login screen.
class ApiClient {
  final Dio dio;
  final TokenStorage storage;
  void Function()? onUnauthorized;

  ApiClient({TokenStorage? storage, Dio? dio})
      : storage = storage ?? TokenStorage(),
        dio = dio ??
            Dio(BaseOptions(
              baseUrl: Config.apiBaseUrl,
              // Generous timeouts: a free-tier host can cold-start (~50s) after
              // idling, so the first request must not give up too early.
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
            )) {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await this.storage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await this.storage.clear();
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));
  }

  /// Extracts a human-readable message from a Dio error if the backend sent one.
  static String messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) return data['error'] as String;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Impossible de joindre le serveur. Le backend est-il lancé ?';
      }
    }
    return 'Une erreur est survenue.';
  }
}
