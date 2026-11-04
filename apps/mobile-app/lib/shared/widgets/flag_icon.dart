import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

/// A country flag drawn as an image. Use this instead of flag emoji
/// ('🇹🇿'): Windows has no flag emoji, so on the desktop build those show as
/// plain letters or nothing at all.
class FlagIcon extends StatelessWidget {
  /// ISO 3166-1 alpha-2 code, e.g. `TZ`, `GB`.
  final String countryCode;

  /// Flag height; width follows at 4:3.
  final double size;

  const FlagIcon(this.countryCode, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CountryFlag.fromCountryCode(
      countryCode,
      theme: ImageTheme(
        width: size * 4 / 3,
        height: size,
        shape: RoundedRectangle(size / 6),
      ),
    );
  }
}
