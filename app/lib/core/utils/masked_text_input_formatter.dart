import 'package:flutter/services.dart';

class MaskedTextInputFormatter extends TextInputFormatter {
  final String mask;
  final String separator;

  MaskedTextInputFormatter({required this.mask, required this.separator});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isNotEmpty) {
      if (newValue.text.length > oldValue.text.length) {
        if (newValue.text.length > mask.length) return oldValue;
      }
    }

    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String result = '';
    int currentIndex = 0;

    for (int i = 0; i < mask.length; i++) {
      if (currentIndex >= text.length) break;
      if (mask[i] == '0') {
        result += text[currentIndex];
        currentIndex++;
      } else {
        result += mask[i];
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}