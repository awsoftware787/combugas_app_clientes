import 'package:combugas_clientes/features/pedidos/controllers/pedido_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carga catálogo, mínimos y clasifica croquetas', () async {
    final repository = _Repository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(pedidoControllerProvider.notifier).load();
    final state = container.read(pedidoControllerProvider);
    expect(state.status, PedidoStatus.ready);
    expect(state.producto(2)?.precioCentavos, 60000);
    expect(state.bultos.single.id, 20);
    expect(state.montosMinimos.litros, 40);
  });

  test('un refresh fallido conserva catálogo anterior', () async {
    final repository = _Repository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(pedidoControllerProvider.notifier);
    await controller.load();
    repository.fail = true;
    await controller.load(refresh: true);
    final state = container.read(pedidoControllerProvider);
    expect(state.status, PedidoStatus.ready);
    expect(state.productos, hasLength(2));
    expect(state.error, contains('lista anterior'));
  });
}

ProviderContainer _container(_Repository repository) => ProviderContainer(
  overrides: [pedidoRepositoryProvider.overrideWithValue(repository)],
);

final class _Repository implements PedidoRepositoryContract {
  @override
  Future<CancelarPedidoResult> cancelarPedido(int pedidoId) =>
      throw UnimplementedError();
  @override
  Future<List<PedidoHistorial>> getPedidos(int clienteId) async => const [];
  @override
  Future<PedidoSeguimientoInfo> getUnPedido(int pedidoId) =>
      throw UnimplementedError();
  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest request) =>
      throw UnimplementedError();
  @override
  Future<List<TiempoFase>> getTiempos() async => const [];
  bool fail = false;
  @override
  Future<List<Producto>> getPrecios() async {
    if (fail) throw Exception('offline');
    return const [
      Producto(
        id: 2,
        descripcion: 'CILINDRO',
        presentacion: '30 KG',
        servicioId: 1,
        precioCentavos: 60000,
      ),
      Producto(
        id: 20,
        descripcion: 'BULTO ADULTO 20 KG',
        presentacion: 'BULTO ADULTO 20 KG',
        servicioId: 9,
        precioCentavos: 50000,
      ),
    ];
  }

  @override
  Future<MontosMinimos> getMontosMinimos() async =>
      const MontosMinimos(dineroCentavos: 50000, litros: 40);
}
