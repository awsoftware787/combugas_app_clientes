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

final currentEnvironment = AppEnvironment.fromName(_environmentName);
