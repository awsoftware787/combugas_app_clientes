import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/data/pedidos_soap_service.dart';
import 'package:combugas_clientes/features/pedidos/models/calificacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const request = CalificacionRequest(
    entregado: true,
    puntuacion: 5,
    comentarios: 'Excelente',
    pedidoId: 321,
    clienteId: 12,
  );

  test('repository delega calificarServicio y devuelve éxito', () async {
    final service = _Service();
    final result = await PedidoRepository(service).calificarServicio(request);
    expect(result.mensaje, 'OK');
    expect(service.received, same(request));
  });

  test('repository propaga error de calificarServicio', () async {
    final repository = PedidoRepository(
      _Service(error: const WebServiceException('RECHAZADO')),
    );
    await expectLater(
      repository.calificarServicio(request),
      throwsA(isA<WebServiceException>()),
    );
  });
}

final class _Service implements PedidosService {
  _Service({this.error});
  final Object? error;
  CalificacionRequest? received;

  @override
  Future<CalificacionResult> calificarServicio(
    CalificacionRequest request,
  ) async {
    received = request;
    if (error != null) throw error!;
    return const CalificacionResult(mensaje: 'OK');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
