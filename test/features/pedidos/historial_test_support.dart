import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';

final class FakeHistorialRepository implements PedidoRepositoryContract {
  FakeHistorialRepository({
    List<PedidoHistorial>? pedidos,
    this.getPedidosHandler,
    this.cancelHandler,
  }) : pedidos = pedidos ?? [];

  List<PedidoHistorial> pedidos;
  Future<List<PedidoHistorial>> Function(int clienteId)? getPedidosHandler;
  Future<CancelarPedidoResult> Function(int pedidoId)? cancelHandler;
  int getPedidosCalls = 0;
  int cancelCalls = 0;

  @override
  Future<List<PedidoHistorial>> getPedidos(int clienteId) async {
    getPedidosCalls++;
    return getPedidosHandler?.call(clienteId) ?? pedidos;
  }

  @override
  Future<CancelarPedidoResult> cancelarPedido(int pedidoId) async {
    cancelCalls++;
    return cancelHandler?.call(pedidoId) ??
        const CancelarPedidoResult(mensaje: 'CANCELADO');
  }

  @override
  Future<PedidoSeguimientoInfo> getUnPedido(int pedidoId) =>
      throw UnimplementedError();
  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest request) =>
      throw UnimplementedError();
  @override
  Future<List<Producto>> getPrecios() async => const [];
  @override
  Future<MontosMinimos> getMontosMinimos() async =>
      const MontosMinimos.empty();
  @override
  Future<List<TiempoFase>> getTiempos() async => const [];
}

final class FakeHistoryAuthRepository implements AuthRepositoryContract {
  @override
  SessionData? getSession() => const SessionData(
    claveUsuario: 12,
    nombreUsuario: 'CLIENTE',
    claveTelefono: 2,
    subcanalUsuario: 1,
  );
  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
}
