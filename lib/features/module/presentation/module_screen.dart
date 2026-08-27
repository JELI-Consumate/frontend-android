import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/module_providers.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import 'article_module_screen.dart';
import 'quiz_module_screen.dart';
import 'reflection_module_screen.dart';
import 'simulation_module_screen.dart';
import 'video_module_screen.dart';
import 'widgets/module_async_scaffold.dart';

/// Titik masuk konsumsi konten satu module -- ambil `GET /modules/{id}`
/// lalu alihkan ke layar yang sesuai berdasarkan tipe konten halaman
/// pertamanya. Modul saat ini selalu tepat satu halaman (lihat
/// `ModuleDetail.firstPage`), jadi tidak ada navigasi antar-halaman di sini.
class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({super.key, required this.moduleId});

  final int moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleAsync = ref.watch(moduleDetailProvider(moduleId));

    return switch (moduleAsync) {
      AsyncData(:final value) => _ModuleContentRouter(module: value),
      AsyncError() => const ModuleErrorScaffold(),
      _ => const ModuleLoadingScaffold(),
    };
  }
}

class _ModuleContentRouter extends StatelessWidget {
  const _ModuleContentRouter({required this.module});

  final ModuleDetail module;

  @override
  Widget build(BuildContext context) {
    final page = module.firstPage;
    if (page == null) {
      return ModuleErrorScaffold(
        title: module.title,
        message: 'Modul ini belum punya konten.',
      );
    }

    return switch (page.content) {
      VideoPageContent() => VideoModuleScreen(module: module, page: page),
      ArticlePageContent() => ArticleModuleScreen(module: module, page: page),
      QuizPageContent() => QuizModuleScreen(module: module, page: page),
      SimulationPageContent() => SimulationModuleScreen(
        module: module,
        page: page,
      ),
      ReflectionPageContent() => ReflectionModuleScreen(
        module: module,
        page: page,
      ),
    };
  }
}
