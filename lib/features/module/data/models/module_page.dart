import 'package:flutter/foundation.dart';

import '../../../learning/data/models/learning_status.dart';
import 'content/article_content.dart';
import 'content/quiz_content.dart';
import 'content/reflection_content.dart';
import 'content/simulation_content.dart';
import 'content/video_content.dart';

/// Cermin dari `ContentableType` enum di backend -- 5 jenis konten yang
/// benar-benar tersimpan (beda dari `ModuleType` yang 8 macam; lihat
/// `ModuleContentType` di fitur learning: `opening`/`materi`/`infografis`/
/// `komik` empat-empatnya sama-sama konten [ContentType.article] di sini,
/// cuma beda label/ikon tampilan).
enum ContentType {
  video,
  article,
  quiz,
  simulation,
  reflection,
  unknown;

  static ContentType fromJson(Object? value) {
    return switch (value) {
      'video' => ContentType.video,
      'article' => ContentType.article,
      'quiz' => ContentType.quiz,
      'simulation' => ContentType.simulation,
      'reflection' => ContentType.reflection,
      _ => ContentType.unknown,
    };
  }
}

/// Union dari 5 jenis konten satu module_page. Sealed supaya `switch` di
/// layar module (lihat `ModuleScreen`) exhaustive -- nambah jenis konten
/// baru nanti bakal ditandai analyzer di semua tempat yang perlu diupdate.
sealed class ModulePageContent {
  const ModulePageContent();

  factory ModulePageContent.fromJson(
    ContentType type,
    Map<String, dynamic> json,
  ) {
    return switch (type) {
      ContentType.video => VideoPageContent(VideoContent.fromJson(json)),
      ContentType.article => ArticlePageContent(ArticleContent.fromJson(json)),
      ContentType.quiz => QuizPageContent(QuizContent.fromJson(json)),
      ContentType.simulation => SimulationPageContent(
        SimulationContent.fromJson(json),
      ),
      ContentType.reflection => ReflectionPageContent(
        ReflectionContent.fromJson(json),
      ),
      ContentType.unknown => throw ArgumentError(
        'Tipe konten module_page tidak dikenali.',
      ),
    };
  }
}

class VideoPageContent extends ModulePageContent {
  const VideoPageContent(this.content);
  final VideoContent content;
}

class ArticlePageContent extends ModulePageContent {
  const ArticlePageContent(this.content);
  final ArticleContent content;
}

class QuizPageContent extends ModulePageContent {
  const QuizPageContent(this.content);
  final QuizContent content;
}

class SimulationPageContent extends ModulePageContent {
  const SimulationPageContent(this.content);
  final SimulationContent content;
}

class ReflectionPageContent extends ModulePageContent {
  const ReflectionPageContent(this.content);
  final ReflectionContent content;
}

/// Satu halaman di dalam module (`GET /modules/{id}` -> `pages[]`). Modul
/// saat ini selalu punya persis satu halaman (lihat `ModuleSeeder`), tapi
/// modelnya tetap dibuat generik per-halaman mengikuti bentuk API.
@immutable
class ModulePage {
  const ModulePage({
    required this.id,
    required this.order,
    required this.contentType,
    required this.content,
    required this.status,
    required this.lastPosition,
  });

  final int id;
  final int order;
  final ContentType contentType;
  final ModulePageContent content;
  final LearningStatus status;
  final int lastPosition;

  factory ModulePage.fromJson(Map<String, dynamic> json) {
    final contentType = ContentType.fromJson(json['content_type']);
    final rawContent = json['content'] as Map<String, dynamic>? ?? const {};
    final rawProgress = json['progress'] as Map<String, dynamic>?;

    return ModulePage(
      id: (json['id'] as num).toInt(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      contentType: contentType,
      content: ModulePageContent.fromJson(contentType, rawContent),
      status: LearningStatus.fromJson(rawProgress?['status']),
      lastPosition: (rawProgress?['last_position'] as num?)?.toInt() ?? 0,
    );
  }
}
