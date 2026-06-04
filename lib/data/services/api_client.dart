import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Client HTTP basé sur [Dio].
///
/// Fournit une configuration centralisée pour les appels API REST :
/// - Base URL configurable
/// - Timeouts
/// - Intercepteur d'authentification (token Firebase)
/// - Intercepteur de logging
class ApiClient {
  late final Dio _dio;

  final FirebaseAuth _auth;

  /// Crée un [ApiClient] configuré.
  ///
  /// [baseUrl] — URL de base de l'API (ex: `https://api.example.com/v1`).
  /// [firebaseAuth] — Instance optionnelle pour l'injection de dépendance.
  ApiClient({required String baseUrl, FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteur d'authentification — injecte le token Firebase ID.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = _auth.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );

    // Intercepteur de logging (activé uniquement en mode debug).
    assert(() {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
      return true;
    }());
  }

  // -------------------------------------------------------------------------
  // Accès à l'instance Dio brute (pour les cas avancés)
  // -------------------------------------------------------------------------

  /// Instance [Dio] sous-jacente.
  Dio get dio => _dio;

  // -------------------------------------------------------------------------
  // Méthodes HTTP raccourcies
  // -------------------------------------------------------------------------

  /// Effectue une requête GET.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Effectue une requête POST.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Effectue une requête PUT.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Effectue une requête PATCH.
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Effectue une requête DELETE.
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
