import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/complaint_agency.dart';

/// "Bingung harus mengadu ke mana?" — pilih masalah, tampilkan lembaga relevan.
class CategoryGuide extends StatefulWidget {
  const CategoryGuide({
    super.key,
    required this.categories,
    required this.onOpenAgency,
  });

  final List<ComplaintCategory> categories;
  final ValueChanged<String> onOpenAgency;

  @override
  State<CategoryGuide> createState() => _CategoryGuideState();
}

class _CategoryGuideState extends State<CategoryGuide> {
  String? _openId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final category in widget.categories) ...[
          _CategoryTile(
            category: category,
            open: _openId == category.id,
            onToggle: () => setState(
              () => _openId = _openId == category.id ? null : category.id,
            ),
            onOpenAgency: widget.onOpenAgency,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.open,
    required this.onToggle,
    required this.onOpenAgency,
  });

  final ComplaintCategory category;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onOpenAgency;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.problem,
                      style: AppTypography.titleSmall.copyWith(
                        color: open ? AppColors.primary : AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AppDuration.fast,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            Divider(color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LEMBAGA YANG RELEVAN', style: AppTypography.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final agency in category.agencies)
                        _AgencyChip(
                          agency: agency,
                          onTap: () => onOpenAgency(agency.slug),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgencyChip extends StatelessWidget {
  const _AgencyChip({required this.agency, required this.onTap});

  final ComplaintCategoryAgency agency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            agency.shortName,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
