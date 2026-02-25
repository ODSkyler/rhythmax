import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class OverflowMarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const OverflowMarqueeText({
    super.key,
    required this.text,
    required this.style,
  });

  bool _isOverflowing(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    return textPainter.width > maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isOverflow =
        _isOverflowing(text, style, constraints.maxWidth);

        if (isOverflow) {
          return SizedBox(
            height: (style.fontSize ?? 14) + 6,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,   // start transparent
                    0.00,  // VERY quick fade-in (soft left)
                    0.88,  // hold full opacity
                    1.0,   // fade out right
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Marquee(
                text: text,
                style: style,
                velocity: 25,
                blankSpace: 40,
                pauseAfterRound: const Duration(seconds: 1),
              ),
            ),
          );
        }

        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}
