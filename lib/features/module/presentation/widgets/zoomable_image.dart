import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Batas lebar dekode untuk gambar konten (infografis/komik). Foto asli dari
/// admin bisa 2-4 MB @ 3000px+ -- kalau di-dekode full-res, satu gambar bisa
/// makan puluhan MB RAM dan gagal diam-diam di HP kelas menengah. Dibatasi
/// ke ~2x lebar layar; masih tajam, tapi jauh lebih ringan.
int _decodeWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (size.width * dpr).clamp(720, 2160).round();
}

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
          cacheWidth: _decodeWidth(context),
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
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      cacheWidth: _decodeWidth(context),
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
