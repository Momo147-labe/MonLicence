import 'dart:math';

class LicenceGenerator {
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _rnd = Random();

  static String generate() {
    return List.generate(6, (i) => _generateBlock()).join('-');
  }

  static String _generateBlock() {
    return String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
      ),
    );
  }
}
