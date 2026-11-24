import 'package:flutter/material.dart';

/// PROMS brand palette — premium charcoal + gold.
///
/// These are the canonical brand colors. Functional/status colors
/// (success green, error red, warning orange) are intentionally kept
/// elsewhere for readability and are not part of the brand identity.
class Brand {
  Brand._();

  /// Primary brand surface — deep charcoal. Used for app bars, headers,
  /// primary filled buttons, and dark emphasis.
  static const Color primary = Color(0xFF111317);

  /// Graphite partner used for subtle header/gradient depth on charcoal.
  static const Color primaryGradient = Color(0xFF2B2F36);

  /// Accent — metallic gold. Used for highlights, active states,
  /// selected indicators, and small points of emphasis on dark surfaces.
  static const Color gold = Color(0xFFD4AF37);

  /// Slightly deeper gold for pressed/hover or text-on-light emphasis.
  static const Color goldDeep = Color(0xFFB8921F);

  /// Light app background.
  static const Color surface = Color(0xFFF9FAFB);
}
