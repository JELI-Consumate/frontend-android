import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/video_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/module_repository.dart';
import 'widgets/mark_complete_button.dart';
import 'widgets/module_header.dart';

/// Modul tipe `video` -- video-nya sendiri diputar DI LUAR app (YouTube
/// app/browser), bukan di-embed. Sengaja: player YouTube tertanam butuh
/// webview + dependency lebih berat, sedangkan buka eksternal cukup dengan
/// `url_launcher` dan jauh lebih gampang diuji. Konsekuensinya progress
/// putarnya tidak dilacak detik-per-detik -- selesainya ditandai manual
/// lewat [MarkCompleteButton].
class VideoModuleScreen extends ConsumerStatefulWidget {
  const VideoModuleScreen({
    super.key,
    required this.module,
    required this.page,
  });

  final ModuleDetail module;
  final ModulePage page;

  @override
  ConsumerState<VideoModuleScreen> createState() => _VideoModuleScreenState();
}

class _VideoModuleScreenState extends ConsumerState<VideoModuleScreen> {
  late bool _completed = widget.page.status.isCompleted;
  bool _busy = false;

  VideoContent get _content =>
      (widget.page.content as VideoPageContent).content;

  Future<void> _openVideo() async {
    final uri = Uri.tryParse(_content.youtubeUrl);
    final opened = uri == null
        ? false
        : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka video. Coba lagi.')),
      );
    }
  }

  Future<void> _markComplete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(moduleRepositoryProvider)
          .completeModulePage(widget.page.id);
      if (mounted) setState(() => _completed = true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ModuleHeader(module: widget.module),
            if (_content.description case final description?
                when description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: AppTypography.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.lg),
            _Thumbnail(videoId: _content.youtubeVideoId, onTap: _openVideo),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Tonton di YouTube',
              trailingIcon: Icons.open_in_new,
              onPressed: _openVideo,
            ),
            if (_content.promptQuestion case final prompt?) ...[
              const SizedBox(height: AppSpacing.lg),
              _PromptCard(question: prompt),
            ],
            const SizedBox(height: AppSpacing.xl),
            MarkCompleteButton(
              completed: _completed,
              busy: _busy,
              onPressed: _markComplete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.videoId, required this.onTap});

  final String? videoId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Material(
        color: AppColors.ink,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (videoId != null)
                Image.network(
                  'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertanyaan Pemantik',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(question, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
