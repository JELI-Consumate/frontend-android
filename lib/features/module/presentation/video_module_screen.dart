import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' show WebViewPlatform;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/video_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/module_repository.dart';
import 'widgets/module_bottom_bar.dart';
import 'widgets/module_continue_button.dart';
import 'widgets/module_header.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_top_bar.dart';

/// Modul tipe `video` -- videonya diputar LANGSUNG di dalam app lewat
/// `youtube_player_iframe` (webview terbungkus IFrame Player API resmi
/// YouTube), bukan cuma buka app/browser YouTube secara eksternal. Progress
/// putarnya tetap tidak dilacak detik-per-detik -- selesainya ditandai
/// otomatis begitu tombol gabungan di [ModuleBottomBar] ditekan, sama seperti
/// artikel (lihat `_continue`).
///
/// Player-nya BARU dibuat begitu thumbnail disentuh (bukan langsung di
/// `initState`) -- bikin WebView + memuat IFrame Player API itu berat, dan
/// kalau dikerjakan begitu layar ini muncul, transisi buka layarnya jadi
/// nge-lag/patah-patah walau pengguna belum tentu jadi nonton videonya.
/// Menunda sampai user benar-benar niat nonton bikin buka layarnya instan.
///
/// Kalau [VideoContent.youtubeVideoId] tidak berhasil diekstrak backend
/// (URL-nya tidak dikenali polanya) atau platform webview tidak tersedia,
/// tap thumbnail turun ke perilaku lama: buka eksternal lewat [url_launcher].
class VideoModuleScreen extends ConsumerStatefulWidget {
  const VideoModuleScreen({
    super.key,
    required this.module,
    required this.page,
    required this.nav,
  });

  final ModuleDetail module;
  final ModulePage page;
  final ModulePageNav nav;

  @override
  ConsumerState<VideoModuleScreen> createState() => _VideoModuleScreenState();
}

class _VideoModuleScreenState extends ConsumerState<VideoModuleScreen> {
  late bool _completed = widget.page.status.isCompleted;
  bool _busy = false;

  YoutubePlayerController? _playerController;

  VideoContent get _content =>
      (widget.page.content as VideoPageContent).content;

  // WebViewPlatform.instance cuma null kalau tidak ada implementasi platform
  // webview yang teregistrasi -- selalu ada di app sungguhan
  // (webview_flutter_android auto-register), tapi TIDAK ada di widget test
  // (flutter_test tidak menjalankan plugin registration). Kalau null, atau
  // videoId gagal diekstrak backend, tidak ada apa pun yang bisa ditanam --
  // tap thumbnail turun ke buka eksternal, bukan crash.
  bool get _canEmbed =>
      _content.youtubeVideoId != null && WebViewPlatform.instance != null;

  void _activatePlayer() {
    if (!_canEmbed || _playerController != null) return;
    setState(() {
      _playerController = YoutubePlayerController.fromVideoId(
        videoId: _content.youtubeVideoId!,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    });
  }

  @override
  void dispose() {
    _playerController?.close();
    super.dispose();
  }

  Future<void> _openVideo() async {
    final uri = Uri.tryParse(_content.youtubeUrl);
    final opened = uri == null
        ? false
        : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Gagal Membuka Video',
        message: 'Tidak bisa membuka video. Coba lagi.',
      );
    }
  }

  /// Tandai selesai (kalau belum) lalu pindah ke halaman/module berikutnya
  /// lewat `widget.nav.onAdvance` -- SATU tombol untuk keduanya, dulu 2
  /// tombol terpisah ("Tandai Selesai" di sini + "Modul Selanjutnya" di
  /// footer luar).
  Future<void> _continue() async {
    if (!_completed) {
      final ok = await _markComplete();
      if (!ok || !mounted) return;
    }
    widget.nav.onAdvance();
  }

  Future<bool> _markComplete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(moduleRepositoryProvider)
          .completeModulePage(widget.page.id);
      if (mounted) setState(() => _completed = true);
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Menandai Selesai',
          message: error.message,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModuleTopBar(
        position: widget.nav.modulePosition,
        total: widget.nav.moduleTotal,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleHeader(module: widget.module),
              if (_content.description case final description?
                  when description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_playerController case final controller?)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: YoutubePlayer(
                    controller: controller,
                    aspectRatio: 16 / 9,
                  ),
                )
              else
                _Thumbnail(
                  videoId: _content.youtubeVideoId,
                  onTap: _canEmbed ? _activatePlayer : _openVideo,
                ),
              const SizedBox(height: AppSpacing.xs),
              if (_canEmbed)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openVideo,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Buka di aplikasi YouTube'),
                  ),
                )
              else
                PrimaryButton(
                  label: 'Tonton di YouTube',
                  trailingIcon: Icons.open_in_new,
                  onPressed: _openVideo,
                ),
              if (_content.promptQuestion case final prompt?) ...[
                const SizedBox(height: AppSpacing.lg),
                _PromptCard(question: prompt),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: ModuleBottomBar(
        pageCount: widget.nav.pageCount,
        pageIndex: widget.nav.pageIndex,
        onDotTap: widget.nav.onDotTap,
        child: ModuleContinueButton(
          hasNext: widget.nav.hasNext,
          busy: _busy,
          onPressed: _continue,
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
                Text(
                  question,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
