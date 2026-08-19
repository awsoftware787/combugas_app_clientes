import 'dart:convert';

import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/create_order.dart';
import '../models/pedido_historial.dart';
import '../models/producto.dart';
import '../presentation/pedido_formatters.dart';

final class PedidosSoapParser {
  const PedidosSoapParser();

  List<Producto> parsePrecios(XmlDocument document) {
    final payload = _response(document, 'getPrecios');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    return _list(payload.data)
        .map(
          (item) => Producto(
            id: _int(item['_idProducto']),
            descripcion: _text(item['_descripcionProducto']),
            presentacion: _text(
              item['_presentacionProducto'] ?? item['_descripcionProducto'],
            ),
            servicioId: _int(item['_idServicio']),
            precioCentavos: (_double(item['_precioProducto']) * 100).round(),
          ),
        )
        .toList(growable: false);
  }

  MontosMinimos parseMontosMinimos(XmlDocument document) {
    final payload = _response(document, 'getMontosMinimos');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    final values = _list(payload.data);
    if (values.isEmpty) throw const InvalidSoapResponseException();
    return MontosMinimos(
      dineroCentavos:
          (_double(values.first['montominimo_dinero']) * 100).round(),
      litros: _double(values.first['montominimo_litros']),
    );
  }

  List<TiempoFase> parseTiempos(XmlDocument document) {
    final payload = _response(document, 'getTiemposFases');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    return _list(payload.data)
        .map(
          (item) => TiempoFase(
            id: _int(item['_idTF']),
            tiempo: _text(item['_tiempoTF']),
            unidad: _text(item['_unidad']),
          ),
        )
        .toList(growable: false);
  }

  CreateOrderResult parseCreateOrder(XmlDocument document) {
    final payload = _response(document, 'validaSalvarPedido');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    final id = int.tryParse(payload.data.trim());
    if (id == null || id <= 0) throw const InvalidSoapResponseException();
    return CreateOrderResult(pedidoId: id, mensaje: payload.message);
  }

  List<PedidoHistorial> parsePedidos(XmlDocument document) {
    final payload = _response(document, 'getPedidos');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    return _list(payload.data).map(_pedido).toList(growable: false);
  }

  PedidoSeguimientoInfo parseUnPedido(XmlDocument document) {
    final payload = _response(document, 'getUnPedido');
    if (!payload.succeeded || payload.message != 'OKPED') {
      throw WebServiceException(payload.message);
    }
    final data = _map(payload.data);
    return PedidoSeguimientoInfo(
      direccion: _direccion(data),
      asignaciones: _mapList(data['_asignacion'])
          .map(
            (item) => PedidoAsignacion(
              operadorId: _int(item['_idOperador']),
              nombreOperador: _text(item['_nombreOperador']),
              rutaId: _int(item['_idRuta']),
              vehiculo: _vehiculo(item['_Vehiculo']),
            ),
          )
          .toList(growable: false),
    );
  }

  CancelarPedidoResult parseCancelarPedido(XmlDocument document) {
    final payload = _response(document, 'cancelarPedido');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    return CancelarPedidoResult(mensaje: payload.message);
  }

  PedidoVehiculo? _vehiculo(Object? value) {
    if (value == null) return null;
    try {
      final data = Map<String, dynamic>.from(value as Map);
      return PedidoVehiculo(
        descripcion: _text(data['_descrVehiculo']),
        latitud: _double(data['_latitudVehiculo']),
        longitud: _double(data['_longitudVehiculo']),
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  PedidoHistorial _pedido(Map<String, dynamic> data) => PedidoHistorial(
    id: _int(data['_idPedido']),
    fecha: parsePedidoDate(
      _text(data['_fechaPedido']),
      _text(data['_horaPedido']),
    ),
    direccion: _direccion(data['_direccion']),
    metodoPago: _text(data['_descrMetodoPago']),
    productos: _mapList(data['_detallePedido'])
        .map(
          (item) => PedidoHistorialItem(
            productoId: _int(item['_idProducto']),
            descripcion: _text(item['_descrProducto']),
            cantidad: _double(item['_detCantidad']),
            importeCentavos: (_double(item['_detImporte']) * 100).round(),
            servicioId: _int(item['_idServicio']),
            presentacion: _text(item['_presentacionProducto']),
          ),
        )
        .toList(growable: false),
    estatusPedido: _bool(data['_estatusPedido']),
    completo: _bool(data['_completo']),
    confirmadoOperador: _bool(data['_confirmadoOperador']),
    confirmadoCliente: _bool(data['_confirmadoCliente']),
  );

  PedidoDireccion _direccion(Object? value) {
    try {
      final data = Map<String, dynamic>.from(value as Map);
      return PedidoDireccion(
        id: _int(data['_idDireccion']),
        descripcion: _text(data['_descrDireccion']),
        tipoCalle: _text(data['_descr_tipo_calle']),
        calle: _text(data['_descr_calle']),
        idCerrada: _int(data['_id_cerrada']),
        cerrada: _text(data['_descripcion_cerrada']),
        numeroInterior: _text(data['_no_interior']),
        numeroExterior: _text(data['_no_exterior']),
        colonia: _text(data['_descr_colonia']),
        ciudad: _text(data['_descr_ciudad']),
        estado: _text(data['_descr_estado']),
        codigoPostal: _text(data['_descr_cp']),
        latitud: _double(data['_latitud']),
        longitud: _double(data['_longitud']),
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  _SoapPayload _response(XmlDocument document, String method) {
    try {
      final result = document.descendants.whereType<XmlElement>().firstWhere(
        (element) => element.name.local == '${method}Result',
      );
      String value(String name) =>
          result.descendants
              .whereType<XmlElement>()
              .firstWhere((element) => element.name.local == name)
              .innerText
              .trim();
      return _SoapPayload(
        succeeded: value('Result').toLowerCase() == 'true',
        message: value('Message'),
        data: value('Data'),
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  List<Map<String, dynamic>> _list(String value) {
    try {
      final decoded = value.trim().isEmpty ? <dynamic>[] : jsonDecode(value);
      if (decoded is! List) throw const FormatException();
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  Map<String, dynamic> _map(String value) {
    try {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  List<Map<String, dynamic>> _mapList(Object? value) {
    if (value == null) return const [];
    try {
      return (value as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  bool _bool(Object? value) =>
      value == true || value == 1 || '$value'.toLowerCase() == 'true';
  String _text(Object? value) =>
      value == null || value == 'null' ? '' : '$value';
}

final class _SoapPayload {
  const _SoapPayload({
    required this.succeeded,
    required this.message,
    required this.data,
  });
  final bool succeeded;
  final String message;
  final String data;
}
