import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../application/module_providers.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import 'article_module_screen.dart';
import 'quiz_module_screen.dart';
import 'reflection_module_screen.dart';
import 'simulation_module_screen.dart';
import 'video_module_screen.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_bottom_bar.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_top_bar.dart';

class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({
    super.key,
    required this.moduleId,
    this.journeyModuleIds,
  });

  final String moduleId;

  final List<String>? journeyModuleIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleAsync = ref.watch(moduleDetailProvider(moduleId));

    return switch (moduleAsync) {
      AsyncData(:final value) => _ModuleContentRouter(
        module: value,
        journeyModuleIds: journeyModuleIds,
      ),
      AsyncError() => const ModuleErrorScaffold(),
      _ => const ModuleLoadingScaffold(),
    };
  }
}

class _ModuleContentRouter extends StatefulWidget {
  const _ModuleContentRouter({required this.module, this.journeyModuleIds});

  final ModuleDetail module;
  final List<String>? journeyModuleIds;

  @override
  State<_ModuleContentRouter> createState() => _ModuleContentRouterState();
}

class _ModuleContentRouterState extends State<_ModuleContentRouter> {
  final _controller = PageController();

  late final List<ValueNotifier<Widget?>> _footerSinks = List.generate(
    widget.module.pages.length,
    (_) => ValueNotifier<Widget?>(null),
  );

  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    for (final sink in _footerSinks) {
      sink.dispose();
    }
    super.dispose();
  }

  int? get _modulePosition {
    final ids = widget.journeyModuleIds;
    if (ids == null) return null;

    final index = ids.indexOf(widget.module.id);
    return index == -1 ? null : index + 1;
  }

  int? get _moduleTotal => widget.journeyModuleIds?.length;

  String? get _nextModuleId {
    final ids = widget.journeyModuleIds;
    if (ids == null) return null;

    final index = ids.indexOf(widget.module.id);
    if (index == -1 || index + 1 >= ids.length) return null;
    return ids[index + 1];
  }

  void _goToNextModule() {
    final nextModuleId = _nextModuleId;
    if (nextModuleId == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ModuleScreen(
          moduleId: nextModuleId,
          journeyModuleIds: widget.journeyModuleIds,
        ),
      ),
    );
  }

  void _handleAdvance(int fromIndex, int pageCount) {
    if (fromIndex < pageCount - 1) {
      _controller.animateToPage(
        fromIndex + 1,
        duration: AppDuration.normal,
        curve: Curves.easeOut,
      );
      return;
    }

    if (_nextModuleId != null) {
      _goToNextModule();
      return;
    }

    Navigator.of(context).pop();
  }

  void _goToPage(int target) {
    _controller.animateToPage(
      target,
      duration: AppDuration.normal,
      curve: Curves.easeOut,
    );
  }

  ModulePageNav _navFor(int index, int pageCount) {
    final hoisted = pageCount > 1;
    return ModulePageNav(
      modulePosition: _modulePosition,
      moduleTotal: _moduleTotal,
      pageCount: pageCount,
      pageIndex: index,
      onDotTap: hoisted ? _goToPage : null,
      hasNext: index < pageCount - 1 || _nextModuleId != null,
      onAdvance: () => _handleAdvance(index, pageCount),
      chromeHoisted: hoisted,
      footerSink: hoisted ? _footerSinks[index] : null,
    );
  }

  Widget _buildPage(ModulePage page, ModulePageNav nav) {
    return switch (page.content) {
      VideoPageContent() => VideoModuleScreen(
        module: widget.module,
        page: page,
        nav: nav,
      ),
      ArticlePageContent() => ArticleModuleScreen(
        module: widget.module,
        page: page,
        nav: nav,
      ),
      QuizPageContent() => QuizModuleScreen(
        module: widget.module,
        page: page,
        nav: nav,
      ),
      SimulationPageContent() => SimulationModuleScreen(
        module: widget.module,
        page: page,
        nav: nav,
      ),
      ReflectionPageContent() => ReflectionModuleScreen(
        module: widget.module,
        page: page,
        nav: nav,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.module.pages;

    if (pages.isEmpty) {
      return ModuleErrorScaffold(
        title: widget.module.title,
        message: 'Modul ini belum punya konten.',
      );
    }

    if (pages.length == 1) {
      return _buildPage(pages.first, _navFor(0, 1));
    }

    final activePage = _currentPage.clamp(0, pages.length - 1);
    return Scaffold(
      appBar: ModuleTopBar(position: _modulePosition, total: _moduleTotal),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          for (var i = 0; i < pages.length; i++)
            _buildPage(pages[i], _navFor(i, pages.length)),
        ],
      ),
      bottomNavigationBar: ModuleBottomBar(
        pageCount: pages.length,
        pageIndex: activePage,
        onDotTap: _goToPage,
        child: ValueListenableBuilder<Widget?>(
          valueListenable: _footerSinks[activePage],
          builder: (_, footer, _) => footer ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
