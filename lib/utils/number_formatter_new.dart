import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _numberFormat =
      NumberFormat.decimalPattern('es_ES');
  final bool allowNegative;

  const ThousandsSeparatorInputFormatter({this.allowNegative = true});

  static String format(double value) => _numberFormat.format(value);

  static double? parse(String text) {
    if (text.isEmpty) return null;
    String normalized = text.replaceAll('.', '').replaceAll(',', '.');
    try {
      return double.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si está vacío, permitir
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Si es solo un signo negativo, permitir
    if (allowNegative && newValue.text == '-') {
      return newValue;
    }

    // Obtener el texto y la posición del cursor
    String text = newValue.text;
    int cursorPos = newValue.selection.start;

    // Normalizar el texto (convertir comas a puntos)
    text = text.replaceAll(',', '.');

    // Limpiar caracteres no válidos
    if (allowNegative) {
      text = text.replaceAll(RegExp(r'[^\d.-]'), '');
      if (text.contains('-') && !text.startsWith('-')) {
        text = text.replaceAll('-', '');
        text = '-$text';
      }
    } else {
      text = text.replaceAll(RegExp(r'[^\d.]'), '');
    }

    // Manejar decimales
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2) {
        text = '${parts[0]}.${parts[1]}';
      }
      if (parts.length > 1 && parts[1].length > 2) {
        text = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }

    // Convertir a número
    double? number = double.tryParse(text);
    if (number == null) {
      return oldValue;
    }

    // Formatear el número
    String formatted = _numberFormat.format(number);
    if (text.contains('.')) {
      if (!formatted.contains(',')) {
        formatted += ',00';
      } else if (formatted.split(',')[1].length == 1) {
        formatted += '0';
      }
    }

    // Calcular la nueva posición del cursor
    int newCursorPos = cursorPos;
    int oldLen = oldValue.text.length;
    int newLen = formatted.length;

    if (oldLen < newLen) {
      newCursorPos += (newLen - oldLen);
    } else if (oldLen > newLen) {
      newCursorPos = math.max(0, newCursorPos - (oldLen - newLen));
    }

    // Asegurarse de que el cursor esté dentro de los límites
    newCursorPos = math.min(newCursorPos, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
