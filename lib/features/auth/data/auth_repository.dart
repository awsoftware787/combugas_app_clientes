import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_provider.dart';
import '../models/login_result.dart';
import '../models/session_data.dart';
import 'clientes_soap_service.dart';
import 'session_storage.dart';

abstract interface class AuthRepositoryContract {
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  });

  SessionData? getSession();

  Future<void> logout();
}

final class AuthRepository implements AuthRepositoryContract {
  const AuthRepository({
    required ClientesService clientesService,
    required SessionStore sessionStorage,
  }) : _clientesService = clientesService,
       _sessionStorage = sessionStorage;

  final ClientesService _clientesService;
  final SessionStore _sessionStorage;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async {
    final result = await _clientesService.login(
      telefono: telefono,
      contrasena: contrasena,
    );
    if (result is LoginSuccess) {
      await _sessionStorage.saveSession(result.session);
    }
    return result;
  }

  @override
  SessionData? getSession() => _sessionStorage.getSession();

  @override
  Future<void> logout() => _sessionStorage.clearSession();
}

final clientesSoapServiceProvider = Provider<ClientesSoapService>((ref) {
  final service = ClientesSoapService();
  ref.onDispose(service.close);
  return service;
});

final sessionStorageProvider = Provider<SessionStore>((ref) {
  return SessionStorage(ref.watch(localStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  return AuthRepository(
    clientesService: ref.watch(clientesSoapServiceProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
  );
});
