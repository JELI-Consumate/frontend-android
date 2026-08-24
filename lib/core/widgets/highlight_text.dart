import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    this.textAlign = TextAlign.center,
    this.baseStyle,
    this.highlightStyle,
  });

  final String text;
  final TextAlign textAlign;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;

  static final RegExp _marker = RegExp(r'\*\*(.+?)\*\*');

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ?? AppTypography.bodyLarge;
    final highlight = highlightStyle ?? AppTypography.bodyHighlight;

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in _marker.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: highlight));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: textAlign,
      semanticsLabel: text.replaceAll('**', ''),
    );
  }
}
