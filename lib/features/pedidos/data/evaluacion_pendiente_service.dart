import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart';

import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/network/soap_service.dart';

final class EvaluacionPendiente {
  const EvaluacionPendiente({
    required this.pedidoId,
    required this.descripcionDireccion,
  });
  final int pedidoId;
  final String descripcionDireccion;
}

final class EvaluacionPendienteService {
  EvaluacionPendienteService({SoapService? soapService, Uri? endpoint})
    : _soap = soapService ?? SoapService(),
      _endpoint = endpoint;
  final SoapService _soap;
  final Uri? _endpoint;

  Future<EvaluacionPendiente?> consultar(int clienteId) async {
    final document = await _soap.call(
      endpoint: _endpoint ?? ServiceEndpoints.clientes,
      namespace: SoapConstants.namespace,
      methodName: ClientesSoapMethods.pendientes,
      parameters: {'_intClaveCliente': clienteId},
    );
    try {
      final result = document.descendants.whereType<XmlElement>().firstWhere(
        (element) =>
            element.name.local == '${ClientesSoapMethods.pendientes}Result',
      );
      String value(String name) =>
          result.descendants
              .whereType<XmlElement>()
              .firstWhere((element) => element.name.local == name)
              .innerText
              .trim();
      if (value('Result').toLowerCase() != 'true' ||
          value('Message') != 'CONFIRMA') {
        return null;
      }
      final data = jsonDecode(value('Data')) as List;
      if (data.isEmpty) return null;
      final item = Map<String, dynamic>.from(data.first as Map);
      final id = item['Id_Pedido'];
      return EvaluacionPendiente(
        pedidoId: id is num ? id.toInt() : int.parse('$id'),
        descripcionDireccion: '${item['DescripcionDireccion'] ?? ''}',
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  void close() => _soap.close();
}

final evaluacionPendienteServiceProvider = Provider<EvaluacionPendienteService>(
  (ref) {
    final service = EvaluacionPendienteService();
    ref.onDispose(service.close);
    return service;
  },
);
