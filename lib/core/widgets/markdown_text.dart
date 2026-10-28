import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

enum InlineKind { text, bold, italic, strike, link }

class InlineSegment {
  const InlineSegment(this.kind, this.text, [this.url]);

  final InlineKind kind;
  final String text;
  final String? url;

  @override
  bool operator ==(Object other) =>
      other is InlineSegment &&
      other.kind == kind &&
      other.text == text &&
      other.url == url;

  @override
  int get hashCode => Object.hash(kind, text, url);

  @override
  String toString() => 'InlineSegment($kind, $text, $url)';
}

// Subset Markdown inline yang dihasilkan MarkdownEditor admin (Filament):
// [teks](url), **tebal**, ~~coret~~, *miring* / _miring_, dan URL polos.
// shortcut: tidak mendukung format bertumpuk (mis. tebal di dalam link) atau blok (heading/list); ganti ke parser Markdown penuh kalau admin mulai memakainya.
final RegExp _token = RegExp(
  r'\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)|\*\*(.+?)\*\*|~~(.+?)~~|(?<![\w*])\*(?![\s*])(.+?)(?<![\s*])\*|(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)|(https?:\/\/[^\s<>]*[^\s<>.,!?;:)])',
);
final RegExp _escape = RegExp(r'\\([\\`*_{}\[\]()#+\-.!~])');

String _unescape(String text) =>
    text.replaceAllMapped(_escape, (m) => m.group(1)!);

List<InlineSegment> parseInlineMarkdown(String text) {
  final segments = <InlineSegment>[];
  var cursor = 0;
  for (final m in _token.allMatches(text)) {
    if (m.start > cursor) {
      segments.add(
        InlineSegment(
          InlineKind.text,
          _unescape(text.substring(cursor, m.start)),
        ),
      );
    }
    if (m.group(1) != null) {
      segments.add(
        InlineSegment(InlineKind.link, _unescape(m.group(1)!), m.group(2)),
      );
    } else if (m.group(3) != null) {
      segments.add(InlineSegment(InlineKind.bold, _unescape(m.group(3)!)));
    } else if (m.group(4) != null) {
      segments.add(InlineSegment(InlineKind.strike, _unescape(m.group(4)!)));
    } else if (m.group(5) != null || m.group(6) != null) {
      segments.add(
        InlineSegment(
          InlineKind.italic,
          _unescape((m.group(5) ?? m.group(6))!),
        ),
      );
    } else {
      segments.add(InlineSegment(InlineKind.link, m.group(7)!, m.group(7)));
    }
    cursor = m.end;
  }
  if (cursor < text.length) {
    segments.add(
      InlineSegment(InlineKind.text, _unescape(text.substring(cursor))),
    );
  }
  return segments;
}

class MarkdownText extends StatefulWidget {
  const MarkdownText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<MarkdownText> createState() => _MarkdownTextState();
}

class _MarkdownTextState extends State<MarkdownText> {
  final _recognizers = <TapGestureRecognizer>[];
  late List<TextSpan> _spans = _buildSpans();

  @override
  void didUpdateWidget(MarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _spans = _buildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _tap(String url) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    _recognizers.add(recognizer);
    return recognizer;
  }

  List<TextSpan> _buildSpans() => [
    for (final s in parseInlineMarkdown(widget.text))
      switch (s.kind) {
        InlineKind.text => TextSpan(text: s.text),
        InlineKind.bold => TextSpan(
          text: s.text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        InlineKind.italic => TextSpan(
          text: s.text,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        InlineKind.strike => TextSpan(
          text: s.text,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        InlineKind.link => TextSpan(
          text: s.text,
          style: const TextStyle(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: _tap(s.url!),
        ),
      },
  ];

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(style: widget.style, children: _spans),
    textAlign: widget.textAlign,
  );
}
