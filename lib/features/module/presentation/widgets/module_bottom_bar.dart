import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bilah bawah seragam kelima layar konsumsi konten -- dipasang lewat
/// `Scaffold.bottomNavigationBar` supaya SELALU nempel di posisi paling
/// bawah layar, bukan ikut discroll di dalam body seperti sebelumnya.
/// Isinya indikator titik posisi halaman (cuma tampil kalau module ini py
/// >1 halaman) diikuti [child] -- selalu SATU widget aksi (tombol, atau
/// Column kecil berisi hint teks + satu tombol), tidak pernah dua tombol
/// sejajar.
class ModuleBottomBar extends StatelessWidget {
  const ModuleBottomBar({
    super.key,
    required this.child,
    this.pageCount = 1,
    this.pageIndex = 0,
    this.onDotTap,
  });

  final Widget child;
  final int pageCount;
  final int pageIndex;
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pageCount > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pageCount; i++)
                      GestureDetector(
                        onTap: onDotTap == null ? null : () => onDotTap!(i),
                        child: AnimatedContainer(
                          duration: AppDuration.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == pageIndex ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == pageIndex
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
