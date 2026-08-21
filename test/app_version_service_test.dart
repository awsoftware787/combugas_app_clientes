import 'package:combugas_clientes/core/services/app_version_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('usa la versión del paquete sin mostrar el build number', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Combugas',
      packageName: 'combugas_clientes',
      version: '9.9.9',
      buildNumber: '999',
      buildSignature: '',
    );

    expect(await AppVersionService.displayVersion, 'v9.9.9');
  });
}
