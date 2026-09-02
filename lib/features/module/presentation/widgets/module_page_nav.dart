import 'package:flutter/widgets.dart';

@immutable
class ModulePageNav {
  const ModulePageNav({
    this.modulePosition,
    this.moduleTotal,
    required this.pageCount,
    required this.pageIndex,
    this.onDotTap,
    required this.hasNext,
    required this.onAdvance,
    this.chromeHoisted = false,
    this.footerSink,
  });

  factory ModulePageNav.single({VoidCallback? onAdvance}) {
    return ModulePageNav(
      pageCount: 1,
      pageIndex: 0,
      hasNext: false,
      onAdvance: onAdvance ?? _noop,
    );
  }

  static void _noop() {}

  final int? modulePosition;
  final int? moduleTotal;

  final int pageCount;
  final int pageIndex;
  final ValueChanged<int>? onDotTap;

  final bool hasNext;

  final VoidCallback onAdvance;

  final bool chromeHoisted;

  final ValueNotifier<Widget?>? footerSink;
}
