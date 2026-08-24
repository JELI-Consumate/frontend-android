import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/segmented_tabs.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/login_form.dart';
import 'widgets/register_form.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialTab = AuthTab.login});

  static const routeName = '/auth';

  final AuthTab initialTab;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum AuthTab { login, register }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late AuthTab _tab = widget.initialTab;

  void _switchTo(AuthTab tab) {
    if (_tab == tab) return;
    FocusScope.of(context).unfocus();
    setState(() => _tab = tab);
  }

  void _notYetAvailable(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.xs,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedTabs(
                      labels: const ['Masuk', 'Daftar'],
                      activeIndex: _tab.index,
                      onChanged: (index) => _switchTo(AuthTab.values[index]),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    switch (_tab) {
                      AuthTab.login => LoginForm(
                        onSwitchToRegister: () => _switchTo(AuthTab.register),
                        onGooglePressed: () =>
                            _notYetAvailable('Masuk dengan Google'),
                        onForgotPassword: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                      ),
                      AuthTab.register => RegisterForm(
                        onSwitchToLogin: () => _switchTo(AuthTab.login),
                        onGooglePressed: () =>
                            _notYetAvailable('Daftar dengan Google'),
                      ),
                    },
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
