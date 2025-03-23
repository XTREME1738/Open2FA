import 'package:open2fa/i18n.dart';

class Util {
  static String toHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }

  static List<int> fromHex(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError(t('error.invalid_hex'));
    }
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw ArgumentError(t('error.invalid_hex'));
    }
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
