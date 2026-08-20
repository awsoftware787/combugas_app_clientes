final class PerfilCliente {
  const PerfilCliente({
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.cantidadDirecciones,
  });

  final String nombre;
  final String telefono;
  final String? correo;
  final int cantidadDirecciones;

  bool get tieneDireccion => cantidadDirecciones > 0;

  PerfilCliente copyWith({String? correo}) => PerfilCliente(
    nombre: nombre,
    telefono: telefono,
    correo: correo ?? this.correo,
    cantidadDirecciones: cantidadDirecciones,
  );
}

final class PerfilOperationResult {
  const PerfilOperationResult({required this.succeeded, required this.message});

  final bool succeeded;
  final String message;
}
