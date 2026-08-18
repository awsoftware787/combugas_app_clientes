import 'package:flutter/services.dart';

final class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;
    final buffer = StringBuffer();

    if (limited.isNotEmpty) {
      buffer.write('(');
      buffer.write(limited.substring(0, limited.length.clamp(0, 3)));
    }
    if (limited.length >= 3) {
      buffer.write(') ');
      buffer.write(limited.substring(3, limited.length.clamp(3, 6)));
    }
    if (limited.length >= 6) {
      buffer.write('-');
      buffer.write(limited.substring(6));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
