import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/perfil/data/perfil_repository.dart';
import 'package:combugas_clientes/features/perfil/models/perfil_cliente.dart';
import 'package:combugas_clientes/features/perfil/screens/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('muestra perfil, valida correo y guarda el cambio', (
    tester,
  ) async {
    final repository = _FakePerfilRepository();
    final auth = _FakeAuthRepository();
    final harness = _Harness(repository, auth);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    expect(find.text('CLIENTE PRUEBA'), findsOneWidget);
    expect(find.text('(871) 123-4567'), findsOneWidget);
    expect(find.text('No hay correo registrado'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('update-profile-email')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-email-field')),
      'correo-invalido',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile-email')));
    await tester.pump();
    expect(find.text('El email no es válido'), findsOneWidget);
    expect(repository.updateCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('profile-email-field')),
      'cliente@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile-email')));
    await tester.pumpAndSettle();
    expect(repository.updateCalls, 1);
    expect(repository.lastEmail, 'cliente@example.com');
    expect(find.text('cliente@example.com'), findsOneWidget);
  });

  testWidgets('Result=false al eliminar no cierra la sesión', (tester) async {
    final repository = _FakePerfilRepository(
      deleteResult: const PerfilOperationResult(
        succeeded: false,
        message: 'NO ELIMINADA',
      ),
    );
    final auth = _FakeAuthRepository();
    final harness = _Harness(repository, auth);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(find.text('NO ELIMINADA'), findsOneWidget);
    expect(auth.logoutCalls, 0);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Result=true al eliminar cierra sesión y vuelve a Productos', (
    tester,
  ) async {
    final repository = _FakePerfilRepository();
    final auth = _FakeAuthRepository();
    final harness = _Harness(repository, auth);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, 1);
    expect(find.text('PRODUCTOS'), findsOneWidget);
  });

  testWidgets('muestra menú en lugar de Regresar y logout limpia la ruta', (
    tester,
  ) async {
    final repository = _FakePerfilRepository(addresses: 0);
    final auth = _FakeAuthRepository();
    final harness = _Harness(repository, auth);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.text('Regresar'), findsNothing);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Carburaciones'), findsOneWidget);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile-logout')));
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, 1);
    expect(find.text('PRODUCTOS'), findsOneWidget);
  });
}

final class _Harness {
  _Harness(_FakePerfilRepository repository, _FakeAuthRepository auth)
    : container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          perfilRepositoryProvider.overrideWithValue(repository),
        ],
      ),
      router = GoRouter(
        initialLocation: '/perfil',
        routes: [
          GoRoute(path: '/perfil', builder: (_, _) => const PerfilScreen()),
          GoRoute(
            path: '/pedido',
            builder: (_, _) => const Scaffold(body: Text('PEDIDO')),
          ),
          GoRoute(
            path: '/productos',
            builder: (_, _) => const Scaffold(body: Text('PRODUCTOS')),
          ),
          GoRoute(
            path: '/direcciones',
            builder: (_, _) => const Scaffold(body: Text('DIRECCIONES')),
          ),
          GoRoute(
            path: '/direcciones/nueva',
            builder: (_, _) => const Scaffold(body: Text('NUEVA DIRECCIÓN')),
          ),
        ],
      );

  final ProviderContainer container;
  final GoRouter router;

  Widget get widget => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );

  void dispose() {
    router.dispose();
    container.dispose();
  }
}

final class _FakePerfilRepository implements PerfilRepositoryContract {
  _FakePerfilRepository({
    this.addresses = 1,
    this.deleteResult = const PerfilOperationResult(
      succeeded: true,
      message: 'OK',
    ),
  });

  final int addresses;
  final PerfilOperationResult deleteResult;
  int updateCalls = 0;
  String? lastEmail;

  @override
  Future<PerfilCliente> getPerfil(int clienteId) async => PerfilCliente(
    nombre: 'CLIENTE PRUEBA',
    telefono: '8711234567',
    correo: lastEmail,
    cantidadDirecciones: addresses,
  );

  @override
  Future<PerfilOperationResult> actualizarCorreo(
    int clienteId,
    String correo,
  ) async {
    updateCalls++;
    lastEmail = correo;
    return const PerfilOperationResult(succeeded: true, message: 'OK');
  }

  @override
  Future<PerfilOperationResult> eliminarCuenta(int clienteId) async =>
      deleteResult;
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  int logoutCalls = 0;

  @override
  SessionData? getSession() => const SessionData(
    claveUsuario: 12,
    nombreUsuario: 'CLIENTE',
    claveTelefono: 34,
    subcanalUsuario: 1,
  );

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}
