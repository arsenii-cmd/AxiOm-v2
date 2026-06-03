import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Device-service API key. Kept out of source control — pass it at build time:
//   flutter build ... --dart-define=DEVICE_API_KEY=<key>
// Without it the device counter simply stays hidden (graceful degradation).
const _apiKey = String.fromEnvironment('DEVICE_API_KEY');
const _baseUrl = 'https://vpn.arcohouse.space/devices/api/devices';

class DeviceInfo {
  const DeviceInfo({
    required this.username,
    required this.connected,
    required this.limit,
  });

  final String username;
  final int connected;
  final int limit;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        username: json['username'] as String? ?? '',
        connected: (json['connected'] as num?)?.toInt() ?? 0,
        limit: (json['limit'] as num?)?.toInt() ?? 0,
      );
}

/// Extracts token from subscription URL.
/// URL format: https://vpn.arcohouse.space/sub/{token}
String? extractDeviceUsername(String url) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('arcohouse.space')) return null;
    final segments = uri.pathSegments;
    final subIdx = segments.indexOf('sub');
    if (subIdx >= 0 && subIdx + 1 < segments.length) {
      final candidate = segments[subIdx + 1];
      if (candidate.isNotEmpty) return candidate;
    }
  } catch (_) {}
  return null;
}

/// Provider: fetches device count for [token] once per evaluation.
/// Refresh cadence is driven externally by the watching widget (foreground-only
/// 10 s polling + connect/disconnect triggers) via ref.invalidate, so there is
/// no internal timer or keepAlive — the provider disposes when nothing watches it
/// (e.g. when the app is backgrounded and the widget stops polling).
/// Returns null silently on any error.
final deviceCountProvider =
    FutureProvider.autoDispose.family<DeviceInfo?, String>((ref, token) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    final response = await dio.get<dynamic>(
      '$_baseUrl/$token',
      queryParameters: {'key': _apiKey},
      options: Options(responseType: ResponseType.plain),
    );

    final rawBody = response.data?.toString() ?? '';
    if (response.statusCode == 200 && rawBody.isNotEmpty) {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      return DeviceInfo.fromJson(decoded);
    }
  } catch (_) {
    // Graceful degradation — show nothing on failure
  }
  return null;
});
