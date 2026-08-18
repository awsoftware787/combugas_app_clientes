final class SessionData {
  const SessionData({
    required this.claveUsuario,
    required this.nombreUsuario,
    required this.claveTelefono,
    required this.subcanalUsuario,
  });

  final int claveUsuario;
  final String nombreUsuario;
  final int claveTelefono;
  final int subcanalUsuario;

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      claveUsuario: json['claveusuario'] as int,
      nombreUsuario: json['nombreusuario'] as String,
      claveTelefono: json['clavetelefono'] as int,
      subcanalUsuario: json['subcanalusuario'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'claveusuario': claveUsuario,
    'nombreusuario': nombreUsuario,
    'clavetelefono': claveTelefono,
    'subcanalusuario': subcanalUsuario,
  };

  @override
  bool operator ==(Object other) {
    return other is SessionData &&
        other.claveUsuario == claveUsuario &&
        other.nombreUsuario == nombreUsuario &&
        other.claveTelefono == claveTelefono &&
        other.subcanalUsuario == subcanalUsuario;
  }

  @override
  int get hashCode =>
      Object.hash(claveUsuario, nombreUsuario, claveTelefono, subcanalUsuario);
}
