import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/notification/application/notification_listener_controller.dart';
import '../features/onboarding/application/sector_selection_provider.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/sector_selection_screen.dart';
import 'main_shell.dart';
import 'splash_screen.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(notificationListenerControllerProvider).attach());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    if (auth.isLoading && !auth.hasValue) return const SplashScreen();

    final user = auth.value;
    if (user == null) return const _UnauthenticatedFlow();

    final selectedSector = ref.watch(selectedSectorSlugProvider);
    final hasSelectedSector = selectedSector.maybeWhen(
      data: (slug) => slug != null,
      orElse: () => false,
    );
    if (!hasSelectedSector) {
      if (selectedSector.isLoading) return const SplashScreen();
      return const SectorSelectionScreen();
    }

    return const MainShell();
  }
}

class _UnauthenticatedFlow extends StatefulWidget {
  const _UnauthenticatedFlow();

  @override
  State<_UnauthenticatedFlow> createState() => _UnauthenticatedFlowState();
}

class _UnauthenticatedFlowState extends State<_UnauthenticatedFlow> {
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone) return const AuthScreen();

    return OnboardingScreen(
      onFinished: () => setState(() => _onboardingDone = true),
    );
  }
}
