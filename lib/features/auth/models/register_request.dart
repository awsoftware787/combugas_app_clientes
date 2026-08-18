final class RegisterRequest {
  const RegisterRequest({
    required this.nombre,
    required this.telefono,
    required this.contrasena,
  });

  final String nombre;
  final String telefono;
  final String contrasena;
}
