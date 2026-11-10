import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class MockNetworkInterceptor extends Interceptor {
  final SharedPreferences? _prefs;
  final Random _random = Random();

  MockNetworkInterceptor([this._prefs]);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final latency = _prefs?.getInt(AppConstants.prefSimulatedLatencyMs) ?? (400 + _random.nextInt(450));
    final force503 = _prefs?.getBool(AppConstants.prefForce503Error) ?? false;

    await Future<void>.delayed(Duration(milliseconds: latency));

    if (force503) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            statusMessage: 'Service Unavailable (Simulated Recruiter Debug Mode)',
            data: {'error': 'Service temporarily unavailable. Please retry.'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (options.path.contains('/api/v1/sync')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'success', 'timestamp': DateTime.now().toIso8601String()},
        ),
      );
      return;
    }

    handler.next(options);
  }
}
