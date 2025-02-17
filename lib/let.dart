import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

typedef JList = List<dynamic>;
typedef JMap = Map<String, dynamic>;

extension ColorWithHSL on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  Color withSaturation(double saturation) {
    return hsl.withSaturation(clampDouble(saturation, 0.0, 1.0)).toColor();
  }

  Color withLightness(double lightness) {
    return hsl.withLightness(clampDouble(lightness, 0.0, 1.0)).toColor();
  }

  Color withHue(double hue) {
    return hsl.withHue(clampDouble(hue, 0.0, 360.0)).toColor();
  }

  Color addSaturation(double saturation) {
    var h = hsl;
    return h.withSaturation(clampDouble(h.saturation + saturation, 0.0, 1.0)).toColor();
  }

  Color addLightness(double lightness) {
    var h = hsl;
    return h.withLightness(clampDouble(h.lightness + lightness, 0.0, 1.0)).toColor();
  }

  Color addHue(double hue) {
    var h = hsl;
    return h.withHue(clampDouble(h.hue + hue, 0.0, 360.0)).toColor();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      // ignore: deprecated_member_use
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      // ignore: deprecated_member_use
      '${red.toRadixString(16).padLeft(2, '0')}'
      // ignore: deprecated_member_use
      '${green.toRadixString(16).padLeft(2, '0')}'
      // ignore: deprecated_member_use
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

