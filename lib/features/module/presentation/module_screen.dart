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
import 'widgets/module_page_nav.dart';

/// Titik masuk konsumsi konten satu module -- ambil `GET /modules/{id}` lalu
/// alihkan ke layar yang sesuai berdasarkan tipe konten tiap halamannya.
/// Module dengan >1 halaman (mis. video + ringkasan artikel) dirender sebagai
/// kartu yang bisa di-swipe (lihat `_ModuleContentRouter`), bukan cuma
/// halaman pertamanya.
///
/// Navigasi antar-halaman DAN antar-module sama-sama lewat satu tombol yang
/// sama di tiap layar (lihat `ModulePageNav`/`ModuleContinueButton`) -- swipe
/// manual di sini cuma jalan pintas tambahan, bukan satu-satunya cara.
class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({
    super.key,
    required this.moduleId,
    this.journeyModuleIds,
  });

  final int moduleId;

  /// Urutan id seluruh module di journey yang sama (lihat pemanggilnya di
  /// `JourneyDetailScreen`) -- dipakai buat badge "Modul X/Y" di
  /// `ModuleTopBar` dan tombol lanjut di halaman terakhir module ini, lalu
  /// diteruskan lagi ke module berikutnya kalau tombol itu ditekan supaya
  /// rantainya jalan sampai akhir journey, bukan cuma sekali lompat. `null`
  /// kalau module ini dibuka tanpa konteks journey -- badge & tombol
  /// lanjutnya cuma turun ke tampilan "akhir" (tanpa nomor, label "Selesai").
  final List<int>? journeyModuleIds;

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
  final List<int>? journeyModuleIds;

  @override
  State<_ModuleContentRouter> createState() => _ModuleContentRouterState();
}

class _ModuleContentRouterState extends State<_ModuleContentRouter> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _modulePosition {
    final ids = widget.journeyModuleIds;
    if (ids == null) return null;

    final index = ids.indexOf(widget.module.id);
    return index == -1 ? null : index + 1;
  }

  int? get _moduleTotal => widget.journeyModuleIds?.length;

  int? get _nextModuleId {
    final ids = widget.journeyModuleIds;
    if (ids == null) return null;

    final index = ids.indexOf(widget.module.id);
    if (index == -1 || index + 1 >= ids.length) return null;
    return ids[index + 1];
  }

  void _goToNextModule() {
    final nextModuleId = _nextModuleId;
    if (nextModuleId == null) return;

    // pushReplacement, bukan push -- lompat antar-module bukan "buka
    // sub-layar baru", jadi tombol kembali dari module berikutnya langsung
    // ke JourneyDetailScreen, bukan menumpuk balik lewat tiap module yang
    // sudah dilewati.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ModuleScreen(
          moduleId: nextModuleId,
          journeyModuleIds: widget.journeyModuleIds,
        ),
      ),
    );
  }

  /// Dipanggil lewat `ModulePageNav.onAdvance` begitu halaman ke-[fromIndex]
  /// (dari total [pageCount] halaman module ini) beres: pindah ke halaman
  /// berikutnya dalam module ini kalau masih ada, kalau tidak baru lompat ke
  /// module berikutnya di journey, kalau itu juga tidak ada berarti ini akhir
  /// journey-nya -- kembali ke layar sebelumnya.
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

  ModulePageNav _navFor(int index, int pageCount) {
    return ModulePageNav(
      modulePosition: _modulePosition,
      moduleTotal: _moduleTotal,
      pageCount: pageCount,
      pageIndex: index,
      onDotTap: pageCount > 1
          ? (target) => _controller.animateToPage(
              target,
              duration: AppDuration.normal,
              curve: Curves.easeOut,
            )
          : null,
      hasNext: index < pageCount - 1 || _nextModuleId != null,
      onAdvance: () => _handleAdvance(index, pageCount),
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

    // Kasus paling umum (1 halaman) -- render langsung layar tipe kontennya
    // tanpa overhead PageView, persis seperti sebelumnya.
    if (pages.length == 1) {
      return _buildPage(pages.first, _navFor(0, 1));
    }

    return PageView(
      controller: _controller,
      children: [
        for (var i = 0; i < pages.length; i++)
          _buildPage(pages[i], _navFor(i, pages.length)),
      ],
    );
  }
}
