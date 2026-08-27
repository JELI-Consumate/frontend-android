import 'package:flutter/foundation.dart';

/// Konten tipe `video` (`ContentableType::Video` di backend) — satu link
/// YouTube + pertanyaan pemantik opsional yang ditampilkan setelah nonton.
@immutable
class VideoContent {
  const VideoContent({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.promptQuestion,
  });

  final int id;
  final String title;
  final String? description;
  final String youtubeUrl;

  /// Sudah diekstrak backend dari [youtubeUrl] (lihat `VideoContent::youtubeVideoId`
  /// di backend) -- dipakai untuk thumbnail (`img.youtube.com/vi/{id}/...`).
  /// `null` kalau URL-nya tidak dikenali polanya.
  final String? youtubeVideoId;
  final String? promptQuestion;

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      youtubeUrl: json['youtube_url'] as String? ?? '',
      youtubeVideoId: json['youtube_video_id'] as String?,
      promptQuestion: json['prompt_question'] as String?,
    );
  }
}
