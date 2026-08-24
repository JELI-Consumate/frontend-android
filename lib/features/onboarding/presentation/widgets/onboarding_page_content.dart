import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../core/widgets/highlight_text.dart';
import '../../domain/onboarding_page_data.dart';

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({super.key, required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxxxl),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                  const Spacer(),
                  AppIllustration(
                    asset: data.illustrationAsset,
                    semanticLabel: data.illustrationLabel,
                  ),
                  const Spacer(),
                  HighlightText(data.body),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
