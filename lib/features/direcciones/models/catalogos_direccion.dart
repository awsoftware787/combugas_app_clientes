final class Colonia {
  const Colonia({
    required this.id,
    required this.descripcion,
    required this.idCiudad,
    required this.ciudad,
    required this.idEstado,
    required this.estado,
  });
  final int id;
  final String descripcion;
  final int idCiudad;
  final String ciudad;
  final int idEstado;
  final String estado;
}

final class Calle {
  const Calle({required this.id, required this.descripcion});
  final int id;
  final String descripcion;
}

final class Cerrada {
  const Cerrada({required this.id, required this.descripcion});
  final int id;
  final String descripcion;
}
