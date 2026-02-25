import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<Color?> extractAccentFromImage(String imageUrl) async {
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      NetworkImage(imageUrl),
    );

    final baseColor =
        palette.vibrantColor?.color ??
            palette.lightVibrantColor?.color ??
            palette.dominantColor?.color;

    if (baseColor == null) return null;

    final hsl = HSLColor.fromColor(baseColor);

    final adjusted = hsl
        .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0));

    return adjusted.toColor();
  } catch (_) {
    return null;
  }
}

