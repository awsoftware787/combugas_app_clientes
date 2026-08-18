final class SoapConstants {
  const SoapConstants._();

  static const namespace = String.fromEnvironment(
    'SOAP_NAMESPACE',
    defaultValue: 'awserver.noip.me:8888/',
  );
}

final class ClientesSoapMethods {
  const ClientesSoapMethods._();

  static const registroValidacion = 'registroClienteValidacion';
  static const registroDirecto = 'registroClienteDirecto';
  static const login = 'login';
  static const actualizarCorreo = 'actualizaCorreo';
  static const informacionCliente = 'traerInfoCliente';
  static const activarCuenta = 'verificarCuenta';
  static const recuperarContrasena = 'recuperarContrasena';
  static const pendientes = 'pendienteFormulario';
  static const reenviarCodigo = 'reenviarCodigo';
  static const eliminarCuenta = 'eliminarCuenta';
}

final class DireccionesSoapMethods {
  const DireccionesSoapMethods._();

  static const guardar = 'guardaDireccion';
  static const actualizar = 'actualizaDireccion';
  static const obtenerTodas = 'getDirecciones';
  static const obtenerUna = 'getUnaDireccion';
  static const obtenerColonias = 'getColonias';
  static const obtenerCalles = 'getCalles';
  static const obtenerCerradas = 'getCerradas';
  static const obtenerCarburaciones = 'getCarburaciones';
  static const desactivar = 'desactivaDireccion';
}

final class PedidosSoapMethods {
  const PedidosSoapMethods._();

  static const obtenerPrecios = 'getPrecios';
  static const obtenerTiempos = 'getTiemposFases';
  static const guardar = 'validaSalvarPedido';
  static const obtenerTodos = 'getPedidos';
  static const obtenerUno = 'getUnPedido';
  static const cancelar = 'cancelarPedido';
  static const calificar = 'calificarServicio';
  static const obtenerMontosMinimos = 'getMontosMinimos';
}
