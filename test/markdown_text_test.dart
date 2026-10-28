import 'package:flutter_test/flutter_test.dart';
import 'package:consumate/core/widgets/markdown_text.dart';

void main() {
  test('parses bold, italic, links and bare urls', () {
    expect(
      parseInlineMarkdown(
        '**Mobile JKN** _b_ [Situs](https://x.id/a) https://a.id/x_y%20z.html.',
      ),
      const [
        InlineSegment(InlineKind.bold, 'Mobile JKN'),
        InlineSegment(InlineKind.text, ' '),
        InlineSegment(InlineKind.italic, 'b'),
        InlineSegment(InlineKind.text, ' '),
        InlineSegment(InlineKind.link, 'Situs', 'https://x.id/a'),
        InlineSegment(InlineKind.text, ' '),
        InlineSegment(
          InlineKind.link,
          'https://a.id/x_y%20z.html',
          'https://a.id/x_y%20z.html',
        ),
        InlineSegment(InlineKind.text, '.'),
      ],
    );
  });
}
