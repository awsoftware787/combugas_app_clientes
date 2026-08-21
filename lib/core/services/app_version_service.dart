import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract final class AppVersionService {
  static Future<String>? _displayVersion;

  static Future<String> get displayVersion =>
      _displayVersion ??= _loadDisplayVersion();

  static Future<String> _loadDisplayVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'v${packageInfo.version}';
  }
}

final appVersionProvider = Provider<Future<String>>(
  (ref) => AppVersionService.displayVersion,
);
