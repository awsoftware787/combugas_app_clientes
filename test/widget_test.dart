import 'package:combugas_clientes/app.dart';
import 'package:combugas_clientes/core/storage/local_storage.dart';
import 'package:combugas_clientes/core/storage/local_storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mantiene splash mientras resuelve la ruta inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(_MemoryStorage())],
        child: const CombugasApp(),
      ),
    );

    expect(find.byType(CombugasApp), findsOneWidget);
  });
}

final class _MemoryStorage implements LocalStorage {
  final Map<String, Object> _values = {};

  @override
  Future<void> clear() async => _values.clear();

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
}
