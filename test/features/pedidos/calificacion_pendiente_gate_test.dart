import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/data/evaluacion_pendiente_service.dart';
import 'package:combugas_clientes/features/pedidos/widgets/calificacion_pendiente_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'historial_test_support.dart';

void main() {
  testWidgets(
    'consulta al iniciar y abre cuando el servidor cambia a CONFIRMA',
    (tester) async {
      var calls = 0;
      final service = EvaluacionPendienteService(
        endpoint: Uri.parse('http://localhost/ws/clientes.asmx'),
        soapService: SoapService(
          httpClient: SoapHttpClient(
            client: MockClient((_) async {
              calls++;
              return http.Response(
                calls == 1
                    ? _response('NOCONFIRMA', '[]')
                    : _response(
                      'CONFIRMA',
                      '[{"Id_Pedido":777,"DescripcionDireccion":"NEGOCIO"}]',
                    ),
                200,
              );
            }),
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
          evaluacionPendienteServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(service.close);
      EvaluacionPendiente? opened;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: CalificacionPendienteGate(
              pollInterval: const Duration(milliseconds: 50),
              onPending: (pending) => opened = pending,
              child: const Scaffold(body: Text('PEDIDO')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(calls, 1);
      expect(opened, isNull);

      await tester.pump(const Duration(milliseconds: 55));
      await tester.pump();
      expect(calls, greaterThanOrEqualTo(2));
      expect(opened?.pedidoId, 777);
      expect(opened?.descripcionDireccion, 'NEGOCIO');
    },
  );

  testWidgets('una falla temporal no bloquea la aplicación', (tester) async {
    final service = EvaluacionPendienteService(
      endpoint: Uri.parse('http://localhost/ws/clientes.asmx'),
      soapService: SoapService(
        httpClient: SoapHttpClient(
          client: MockClient(
            (_) async => http.Response('respuesta inválida', 200),
          ),
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        evaluacionPendienteServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(service.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CalificacionPendienteGate(
            onPending: (_) => fail('No debe navegar'),
            child: const Scaffold(body: Text('PEDIDO DISPONIBLE')),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('PEDIDO DISPONIBLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _response(String message, String data) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><pendienteFormularioResponse><pendienteFormularioResult>
<Result>true</Result><Message>$message</Message><Data><![CDATA[$data]]></Data>
</pendienteFormularioResult></pendienteFormularioResponse></soap:Body></soap:Envelope>''';
