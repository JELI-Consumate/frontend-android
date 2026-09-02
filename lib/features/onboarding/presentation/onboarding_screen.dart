import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/page_dots.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/onboarding_page_data.dart';
import 'widgets/onboarding_page_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  static const routeName = '/onboarding';

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _pages = onboardingPages;

  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: AppDuration.slow,
      curve: Curves.easeOutCubic,
    );
  }

  void _onCtaPressed() {
    final isLastPage = _index == _pages.length - 1;
    if (isLastPage) {
      widget.onFinished();
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) =>
                    OnboardingPageContent(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xs,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _pages[_index].ctaLabel,
                    onPressed: _onCtaPressed,
                  ),
                  if (_pages.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    PageDots(
                      count: _pages.length,
                      activeIndex: _index,
                      onDotTap: _goTo,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
