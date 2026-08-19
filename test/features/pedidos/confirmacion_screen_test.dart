import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/direcciones/controllers/direccion_controller.dart';
import 'package:combugas_clientes/features/direcciones/data/direccion_repository.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:combugas_clientes/features/pedidos/models/item_pedido.dart';
import 'package:combugas_clientes/features/pedidos/screens/confirmacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'muestra dirección, producto con icono, total, pago y confirmar',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
          direccionRepositoryProvider.overrideWithValue(_DirectionRepository()),
          pedidoRepositoryProvider.overrideWithValue(_PedidoRepository()),
          carritoStoreProvider.overrideWithValue(_CartStore()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(direccionControllerProvider.notifier).load();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConfirmacionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASA'), findsOneWidget);
      expect(find.textContaining('HIDALGO'), findsOneWidget);
      expect(find.text('CILINDRO 30 KG'), findsOneWidget);
      final image = tester.widget<Image>(
        find.byKey(const ValueKey('producto-2-imagen')),
      );
      expect((image.image as AssetImage).assetName, AppAssets.productCylinder);
      expect(find.text('Cantidad: 2'), findsOneWidget);
      expect(find.text(r'$1,200.00'), findsNothing);
      expect(find.text(r'$1200.00'), findsNWidgets(2));
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Tarjeta'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      final confirmButton = find.byKey(const ValueKey('confirm-order'));
      expect(confirmButton, findsOneWidget);
      expect(
        tester.getBottomRight(confirmButton).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
      final confirm = tester.widget<FilledButton>(confirmButton);
      expect(
        confirm.style?.backgroundColor?.resolve(const {}),
        AppColors.addButtonGreen,
      );
      final clear = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('clear-confirmation')),
      );
      expect(clear.style?.foregroundColor?.resolve(const {}), AppColors.accent);
      expect(clear.style?.side?.resolve(const {})?.color, AppColors.accent);

      final accessButton = find.byKey(const ValueKey('access-key-button'));
      await tester.tap(accessButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(accessButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('access-key-field')),
        'PORTÓN 3',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Clave de acceso: PORTÓN 3'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(accessButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('access-key-field')),
        '',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Clave de acceso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _PedidoRepository implements PedidoRepositoryContract {
  @override
  Future<List<TiempoFase>> getTiempos() async => const [
    TiempoFase(id: 2, tiempo: '45', unidad: 'Minutos'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _CartStore implements CarritoStore {
  @override
  List<ItemPedido> read() => [_item];
  @override
  Future<void> save(List<ItemPedido> items) async {}
}

final _item = ItemPedido(
  productoId: 2,
  descripcion: 'CILINDRO 30 KG',
  cantidad: 2,
  importeCentavos: 120000,
  fecha: DateTime(2026),
  servicioId: 1,
  presentacion: '30 KG',
);

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
