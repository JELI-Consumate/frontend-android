import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Gambar konten yang bisa di-tap untuk dibesarkan jadi full-screen (pinch
/// zoom lewat `InteractiveViewer`), lalu diminimize lagi lewat tombol close
/// atau tombol kembali. Dipakai untuk foto infografis/komik dsb -- yang
/// sebelumnya cuma `Image.network` polos, tidak bisa diperbesar sama sekali.
///
/// Loader (spinner) SELALU dibatasi cuma di area gambar itu sendiri lewat
/// `loadingBuilder`, baik versi kecil di dalam konten maupun versi
/// full-screen-nya -- bukan menutupi seluruh layar.
class ZoomableImage extends StatelessWidget {
  const ZoomableImage({
    super.key,
    required this.url,
    this.aspectRatio = 4 / 3,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  final String url;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: _FullScreenImage(url: url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: GestureDetector(
        onTap: () => _openFullScreen(context),
        child: Image.network(
          url,
          width: double.infinity,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return AspectRatio(
              aspectRatio: aspectRatio,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, _, _) => AspectRatio(
            aspectRatio: aspectRatio,
            child: ColoredBox(
              color: AppColors.background,
              child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // Tap di luar gambar (area gelap kosong) ikut menutup --
              // bukan cuma lewat tombol close.
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: GestureDetector(
                    // Tap TEPAT di atas gambarnya sendiri jangan ikut nutup
                    // -- supaya tidak bentrok dengan gestur pinch-zoom.
                    onTap: () {},
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
