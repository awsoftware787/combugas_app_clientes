import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';

PedidoHistorial pedidoFixture({
  int id = 321,
  bool activo = true,
  bool completo = false,
}) => PedidoHistorial(
  id: id,
  fecha: DateTime(2026, 8, 19, 14, 35),
  direccion: direccionPedidoFixture,
  metodoPago: 'Efectivo',
  productos: const [
    PedidoHistorialItem(
      productoId: 2,
      descripcion: 'CILINDRO 30 KG',
      cantidad: 1,
      importeCentavos: 59010,
    ),
    PedidoHistorialItem(
      productoId: 20,
      descripcion: 'BULTO DE 20KG',
      cantidad: 1,
      importeCentavos: 30000,
    ),
  ],
  estatusPedido: activo,
  completo: completo,
  confirmadoOperador: false,
  confirmadoCliente: false,
);

const direccionPedidoFixture = PedidoDireccion(
  id: 9,
  descripcion: 'CASA',
  tipoCalle: 'CALLE',
  calle: 'HIDALGO',
  idCerrada: 1,
  cerrada: '',
  numeroInterior: '',
  numeroExterior: '123',
  colonia: 'CENTRO',
  ciudad: 'TORREÓN',
  estado: 'COAHUILA',
  codigoPostal: '27000',
  latitud: 25.5,
  longitud: -103.4,
);

const pedidoJson = '''[{"_idPedido":321,"_fechaPedido":"19/08/2026","_horaPedido":"14:35:00","_direccion":{"_idDireccion":9,"_descrDireccion":"CASA","_descr_tipo_calle":"CALLE","_descr_calle":"HIDALGO","_id_cerrada":1,"_descripcion_cerrada":"","_no_interior":"","_no_exterior":"123","_descr_colonia":"CENTRO","_descr_ciudad":"TORREÓN","_descr_estado":"COAHUILA","_descr_cp":"27000","_latitud":25.5,"_longitud":-103.4},"_descrMetodoPago":"Efectivo","_detallePedido":[{"_idProducto":2,"_descrProducto":"CILINDRO 30 KG","_detImporte":590.10,"_detCantidad":1},{"_idProducto":20,"_descrProducto":"BULTO DE 20KG","_detImporte":300,"_detCantidad":1}],"_estatusPedido":true,"_completo":false,"_confirmadoOperador":false,"_confirmadoCliente":false}]''';

const seguimientoJson = '''{"_idDireccion":9,"_descrDireccion":"CASA","_descr_tipo_calle":"CALLE","_descr_calle":"HIDALGO","_id_cerrada":1,"_descripcion_cerrada":"","_no_interior":"","_no_exterior":"123","_descr_colonia":"CENTRO","_descr_ciudad":"TORREÓN","_descr_estado":"COAHUILA","_descr_cp":"27000","_latitud":25.5,"_longitud":-103.4,"_asignacion":[{"_idOperador":4,"_nombreOperador":"OPERADOR","_idRuta":8}]}''';
