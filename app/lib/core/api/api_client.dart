  import 'package:dio/dio.dart';
  import 'package:flutter/foundation.dart' show kDebugMode;

  class ApiClient {
    static final Dio dio = _initDio();

    static Dio _initDio() {
      final dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://192.168.1.7:3333',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );


      if (kDebugMode) {
        dio.interceptors.add(
          LogInterceptor(
            requestBody: false,
            responseBody: false,
          ),
        );
      }

      return dio;
    }
  }