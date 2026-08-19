import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/controllers/auth_controller.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/direcciones/controllers/direccion_controller.dart';
import 'package:combugas_clientes/features/direcciones/data/direccion_repository.dart';
import 'package:combugas_clientes/features/direcciones/models/catalogos_direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion_request.dart';
import 'package:combugas_clientes/features/pedidos/controllers/carrito_controller.dart';
import 'package:combugas_clientes/features/pedidos/controllers/confirmacion_controller.dart';
import 'package:combugas_clientes/features/pedidos/controllers/mis_pedidos_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/data/ultimo_pedido_storage.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:combugas_clientes/features/pedidos/models/item_pedido.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'validación correcta guarda, persiste resultado y limpia carrito',
    () async {
      final context = await _context();
      addTearDown(context.container.dispose);
      final result = await context.container
          .read(confirmacionControllerProvider.notifier)
          .submit(accessKey: 'PORTÓN 3');

      expect(result?.pedidoId, 321);
      expect(context.repository.received?.direccionId, 9);
      expect(context.repository.received?.clienteId, 12);
      expect(context.repository.received?.telefonoId, 2);
      expect(context.repository.received?.metodoPagoId, 1);
      expect(
        context.repository.received?.detalleJson,
        '[{"clave":2,"cantidad":1.0,"importe":600.0}]',
      );
      expect(context.repository.received?.observaciones, 'PORTÓN 3');
      expect(context.last.saved?.pedidoId, 321);
      expect(context.container.read(carritoControllerProvider).items, isEmpty);
      expect(
        context.container.read(confirmacionControllerProvider).status,
        ConfirmacionStatus.success,
      );
    },
  );

  test('rechazo de validaSalvarPedido conserva el carrito', () async {
    final context = await _context(
      error: const WebServiceException('NOHORARIO'),
    );
    addTearDown(context.container.dispose);
    expect(
      await context.container
          .read(confirmacionControllerProvider.notifier)
          .submit(),
      isNull,
    );
    expect(
      context.container.read(carritoControllerProvider).items,
      hasLength(1),
    );
    expect(
      context.container.read(confirmacionControllerProvider).message,
      contains('horario'),
    );
  });

  test('pedido creado invalida Mis Pedidos y obliga otra consulta', () async {
    final context = await _context();
    addTearDown(context.container.dispose);
    await context.container.read(misPedidosControllerProvider.notifier).load();
    expect(context.repository.getPedidosCalls, 1);

    await context.container
        .read(confirmacionControllerProvider.notifier)
        .submit();
    await context.container.read(misPedidosControllerProvider.notifier).load();

    expect(context.repository.getPedidosCalls, 2);
  });

  test('error de servidor conserva el carrito', () async {
    final context = await _context(
      error: const WebServiceException('PEDIDOERR'),
    );
    addTearDown(context.container.dispose);
    await context.container
        .read(confirmacionControllerProvider.notifier)
        .submit();
    expect(
      context.container.read(carritoControllerProvider).items,
      hasLength(1),
    );
    expect(
      context.container.read(confirmacionControllerProvider).message,
      contains('procesar'),
    );
  });

  test('timeout conserva carrito y advierte resultado ambiguo', () async {
    final context = await _context(error: const NetworkTimeoutException());
    addTearDown(context.container.dispose);
    await context.container
        .read(confirmacionControllerProvider.notifier)
        .submit();
    expect(
      context.container.read(carritoControllerProvider).items,
      hasLength(1),
    );
    expect(
      context.container.read(confirmacionControllerProvider).message,
      contains('incierto'),
    );
  });

  test('carrito vacío se rechaza antes de invocar el servicio', () async {
    final context = await _context(items: const []);
    addTearDown(context.container.dispose);
    await context.container
        .read(confirmacionControllerProvider.notifier)
        .submit();
    expect(context.repository.calls, 0);
    expect(
      context.container.read(confirmacionControllerProvider).message,
      contains('por lo menos'),
    );
  });
}

Future<_TestContext> _context({Object? error, List<ItemPedido>? items}) async {
  final repository = _PedidoRepository(error);
  final cart = _CartStore(items ?? [_item]);
  final last = _LastStore();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      direccionRepositoryProvider.overrideWithValue(_DirectionRepository()),
      pedidoRepositoryProvider.overrideWithValue(repository),
      carritoStoreProvider.overrideWithValue(cart),
      ultimoPedidoStoreProvider.overrideWithValue(last),
      currentDateTimeProvider.overrideWithValue(
        () => DateTime(2026, 8, 19, 12),
      ),
    ],
  );
  container.read(authControllerProvider);
  await container.read(direccionControllerProvider.notifier).load();
  return _TestContext(container, repository, last);
}

final class _TestContext {
  const _TestContext(this.container, this.repository, this.last);
  final ProviderContainer container;
  final _PedidoRepository repository;
  final _LastStore last;
}

final class _PedidoRepository implements PedidoRepositoryContract {
  _PedidoRepository(this.error);
  final Object? error;
  int calls = 0;
  int getPedidosCalls = 0;
  CreateOrderRequest? received;

  @override
  Future<CancelarPedidoResult> cancelarPedido(int pedidoId) =>
      throw UnimplementedError();
  @override
  Future<List<PedidoHistorial>> getPedidos(int clienteId) async {
    getPedidosCalls++;
    return const [];
  }

  @override
  Future<PedidoSeguimientoInfo> getUnPedido(int pedidoId) =>
      throw UnimplementedError();

  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest request) async {
    calls++;
    received = request;
    if (error != null) throw error!;
    return const CreateOrderResult(pedidoId: 321, mensaje: 'OK');
  }

  @override
  Future<List<TiempoFase>> getTiempos() async => const [
    TiempoFase(id: 2, tiempo: '45', unidad: 'Minutos'),
  ];
  @override
  Future<List<Producto>> getPrecios() async => const [];
  @override
  Future<MontosMinimos> getMontosMinimos() async => const MontosMinimos.empty();
}

final class _CartStore implements CarritoStore {
  _CartStore(this.items);
  List<ItemPedido> items;
  @override
  List<ItemPedido> read() => items;
  @override
  Future<void> save(List<ItemPedido> value) async => items = [...value];
}

final class _LastStore implements UltimoPedidoStore {
  CreateOrderResult? saved;
  @override
  Future<void> save(CreateOrderResult result) async => saved = result;
}

final class _AuthRepository implements AuthRepositoryContract {
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

final class _DirectionRepository implements DireccionRepositoryContract {
  @override
  Future<List<Direccion>> getDirecciones(int clienteId) async => const [
    _address,
  ];
  @override
  Direccion? getSelected() => _address;
  @override
  Future<void> saveSelected(Direccion direccion) async {}
  @override
  Future<void> clearSelected() async {}
  @override
  Future<Direccion> getDireccion(int direccionId) async => _address;
  @override
  Future<List<Colonia>> getColonias() async => const [];
  @override
  Future<List<Calle>> getCalles(int coloniaId) async => const [];
  @override
  Future<List<Cerrada>> getCerradas(int coloniaId) async => const [];
  @override
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  ) => throw UnimplementedError();
  @override
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  ) => throw UnimplementedError();
  @override
  Future<DireccionOperationResult> desactivar(int direccionId, int clienteId) =>
      throw UnimplementedError();
}

const _address = Direccion(
  id: 9,
  descripcion: 'CASA',
  tipoCalle: 'CALLE',
  idCalle: 2,
  calle: 'HIDALGO',
  numeroInterior: '',
  numeroExterior: '123',
  idColonia: 3,
  colonia: 'CENTRO',
  idCiudad: 1,
  ciudad: 'TORREÓN',
  idEstado: 5,
  estado: 'COAHUILA',
  idZona: 0,
  zona: '',
  idCodigoPostal: 0,
  codigoPostal: '',
  referencias: '',
  activa: true,
  latitud: 25.5,
  longitud: -103.4,
  observaciones: '',
  entreCalle1: '',
  entreCalle2: '',
  entreCalle3: '',
  idSegmento: 1,
  cerrada: '',
  requiereClave: false,
  clave: '',
  idRuta: 0,
  tienePedido: false,
);

final _item = ItemPedido(
  productoId: 2,
  descripcion: 'CILINDRO 30 KG',
  cantidad: 1,
  importeCentavos: 60000,
  fecha: DateTime(2026),
  servicioId: 1,
  presentacion: '30 KG',
);
