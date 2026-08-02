import 'package:dio/dio.dart';

import '../config/app_config.dart';

class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
