import '../models/pedido_historial.dart';

DateTime? parsePedidoDate(String fecha, String hora) {
  final dateParts = fecha.split('/');
  final timeParts = hora.split(':');
  if (dateParts.length != 3 || timeParts.length < 2) return null;
  try {
    return DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
    );
  } catch (_) {
    return null;
  }
}

String formatoFechaPedido(DateTime? value) {
  if (value == null) return '';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '${_two(value.day)}/${_two(value.month)}/${value.year} '
      '${_two(hour)}:${_two(value.minute)} $period';
}

String pedidoStatusLabel(PedidoHistorialStatus status) => switch (status) {
  PedidoHistorialStatus.enCurso => 'en curso',
  PedidoHistorialStatus.pendienteConfirmacion => 'por confirmar',
  PedidoHistorialStatus.completo => 'completo',
  PedidoHistorialStatus.cancelado => 'cancelado',
};

String _two(int value) => value.toString().padLeft(2, '0');
