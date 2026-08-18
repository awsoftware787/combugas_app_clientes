abstract final class RegistrationValidators {
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Debe especificar un nombre válido';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.length != 14) {
      return 'El teléfono especificado no es válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? verificationCode(String? value) {
    if (value == null || value.length != 6) {
      return 'El código de verificación no tiene el formato correcto';
    }
    return null;
  }
}
