import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marks every match of [highlight] so users can see why a result matched.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    this.highlight = '',
    this.style,
    this.maxLines,
  });

  final String text;
  final String highlight;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final query = highlight.trim().toLowerCase();
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    var start = 0;
    while (true) {
      final index = lower.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            backgroundColor: AppColors.accent.withValues(alpha: 0.18),
          ),
        ),
      );
      start = index + query.length;
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
