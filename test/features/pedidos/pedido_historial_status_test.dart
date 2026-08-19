import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pedido_historial_fixture.dart';

void main() {
  test('entrega del operador queda por confirmar y no se puede cancelar', () {
    final pedido = pedidoFixture(
      completo: true,
      confirmadoOperador: true,
      confirmadoCliente: false,
    );
    expect(pedido.status, PedidoHistorialStatus.pendienteConfirmacion);
    expect(pedido.puedeCancelar, isFalse);
    expect(pedido.puedeSeguir, isFalse);
  });

  test('sólo pasa a completo después de confirmar el cliente', () {
    final pedido = pedidoFixture(
      completo: true,
      confirmadoOperador: true,
      confirmadoCliente: true,
    );
    expect(pedido.status, PedidoHistorialStatus.completo);
  });
}
