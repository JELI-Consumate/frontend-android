import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_alert_dialog.dart';
import '../../../../core/widgets/primary_button.dart';

class SectorSurveyCard extends StatefulWidget {
  const SectorSurveyCard({
    super.key,
    required this.title,
    required this.description,
    required this.link,
    required this.onComplete,
    this.openLink,
  });

  final String title;
  final String description;
  final String link;

  final Future<void> Function() onComplete;

  final Future<bool> Function(Uri uri)? openLink;

  @override
  State<SectorSurveyCard> createState() => _SectorSurveyCardState();
}

class _SectorSurveyCardState extends State<SectorSurveyCard> {
  bool _opened = false;
  bool _busy = false;

  static Future<bool> _launchExternally(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.link);
    final launcher = widget.openLink ?? _launchExternally;
    final opened = uri == null ? false : await launcher(uri);

    if (!mounted) return;

    if (opened) {
      setState(() => _opened = true);
    } else {
      showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Gagal Membuka Form',
        message: 'Tidak bisa membuka link survei. Coba lagi.',
      );
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.onComplete();
    } on ApiException catch (error) {
      if (mounted) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Menandai Selesai',
          message: error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.description,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Buka Google Form',
            trailingIcon: Icons.open_in_new,
            onPressed: _busy ? null : _open,
          ),
          if (_opened) ...[
            const SizedBox(height: AppSpacing.xxs),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _confirm,
                child: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Saya Sudah Mengisi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
