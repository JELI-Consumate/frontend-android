import 'package:flutter/material.dart';

import 'module_bottom_bar.dart';
import 'module_page_nav.dart';
import 'module_top_bar.dart';

class ModulePageScaffold extends StatefulWidget {
  const ModulePageScaffold({
    super.key,
    required this.nav,
    required this.body,
    this.footer,
    this.backgroundColor,
  });

  final ModulePageNav nav;

  final Widget body;

  final Widget? footer;

  final Color? backgroundColor;

  @override
  State<ModulePageScaffold> createState() => _ModulePageScaffoldState();
}

class _ModulePageScaffoldState extends State<ModulePageScaffold> {
  @override
  void initState() {
    super.initState();
    _publishFooter();
  }

  @override
  void didUpdateWidget(ModulePageScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publishFooter();
  }

  void _publishFooter() {
    final sink = widget.nav.footerSink;
    if (!widget.nav.chromeHoisted || sink == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sink.value = widget.footer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(bottom: false, child: widget.body);

    if (widget.nav.chromeHoisted) {
      final color =
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
      return ColoredBox(color: color, child: body);
    }

    final footer = widget.footer;
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: ModuleTopBar(
        position: widget.nav.modulePosition,
        total: widget.nav.moduleTotal,
      ),
      body: body,
      bottomNavigationBar: footer == null
          ? null
          : ModuleBottomBar(
              pageCount: widget.nav.pageCount,
              pageIndex: widget.nav.pageIndex,
              onDotTap: widget.nav.onDotTap,
              child: footer,
            ),
    );
  }
}
