import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages APK download for updates — persists state, avoids re-download.
class UpdateDownloader with InfraLogger {
  UpdateDownloader({required this.dio});

  final Dio dio;

  // ---- persisted keys ----
  static const _prefsKeyDownloadedPath = 'update_downloaded_path';
  static const _prefsKeyDownloadedSize = 'update_downloaded_size';
  static const _prefsKeyDownloadedUrl = 'update_downloaded_url';

  /// Returns the cached APK path if already downloaded for [url], or null.
  Future<String?> getCachedApk(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_prefsKeyDownloadedUrl);
    final cachedPath = prefs.getString(_prefsKeyDownloadedPath);
    final cachedSize = prefs.getInt(_prefsKeyDownloadedSize) ?? 0;

    if (cachedUrl == url && cachedPath != null) {
      final file = File(cachedPath);
      if (await file.exists() && await file.length() == cachedSize) {
        return cachedPath;
      }
      // Stale cache — clean up
      await _clearCache();
    }
    return null;
  }

  /// Download APK from [url] to temp dir, reporting progress.
  /// Returns the local file path. Caches the result for later install.
  Future<String> downloadApk({
    required String url,
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/axiom_update.apk');
    if (await file.exists()) await file.delete();

    await dio.download(
      url,
      file.path,
      onReceiveProgress: onProgress,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
      ),
    );

    // Persist cache info
    final size = await file.length();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyDownloadedUrl, url);
    await prefs.setString(_prefsKeyDownloadedPath, file.path);
    await prefs.setInt(_prefsKeyDownloadedSize, size);

    return file.path;
  }

  /// Install the APK at [apkPath] using the system package installer.
  /// Deletes the file after a successful launch.
  Future<void> installApk(String apkPath) async {
    await OpenFilex.open(apkPath, type: 'application/vnd.android.package-archive');
    // Give the installer a moment to start, then clean up
    await Future.delayed(const Duration(seconds: 2));
    await _clearCache();
    final file = File(apkPath);
    if (await file.exists()) {
      try { await file.delete(); } catch (_) {}
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKeyDownloadedPath);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        try { await file.delete(); } catch (_) {}
      }
    }
    await prefs.remove(_prefsKeyDownloadedUrl);
    await prefs.remove(_prefsKeyDownloadedPath);
    await prefs.remove(_prefsKeyDownloadedSize);
  }

  /// Clean up any previously downloaded APK (call when update is done).
  Future<void> cleanup() => _clearCache();
}
