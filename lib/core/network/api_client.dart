import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient._();

  static const String _defaultBaseUrl = 'http://localhost:3000';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:3000';

  static String baseUrlForPlatform() {
    if (kIsWeb) return _defaultBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidEmulatorBaseUrl
        : _defaultBaseUrl;
  }

  static Dio create({String? baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? baseUrlForPlatform(),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }
}

