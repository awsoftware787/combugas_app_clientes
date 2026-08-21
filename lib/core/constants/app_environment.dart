import 'package:package_info_plus/package_info_plus.dart';

enum AppEnvironment {
  dev,
  test,
  prod;

  static AppEnvironment fromName(String value) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == value.toLowerCase(),
      orElse: () => AppEnvironment.dev,
    );
  }
}

const _environmentName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
const _configuredAppVersion = String.fromEnvironment('APP_VERSION');

final currentEnvironment = AppEnvironment.fromName(_environmentName);
Future<String>? _appVersion;

Future<String> loadAppVersion() => _appVersion ??= _resolveAppVersion();

Future<String> _resolveAppVersion() async {
  if (_configuredAppVersion.trim().isNotEmpty) {
    return _configuredAppVersion.trim();
  }
  return (await PackageInfo.fromPlatform()).version;
}
