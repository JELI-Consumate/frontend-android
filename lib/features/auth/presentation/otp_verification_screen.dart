import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';

const _kOtpLength = 6;

/// Layar wajib setelah registrasi (dan setelah login ditolak backend karena
/// `EMAIL_NOT_VERIFIED`): input kode OTP 6 digit yang dikirim ke email.
///
/// Verifikasi tidak pernah keluar dari app — tidak ada deep link/browser
/// yang perlu di-resolve, pengguna cuma menyalin kode dari email ke sini.
/// Begitu backend menerima kode yang benar, [AuthController.verifyOtp]
/// mengisi `authControllerProvider` dengan user (yang emailnya kini
/// terverifikasi) sekaligus token baru, dan AppRoot pindah sendiri ke
/// MainShell — layar ini tidak perlu navigasi manual saat sukses.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _code = '';
  int _boxesResetToken = 0;

  String? _error;
  bool _verifying = false;
  bool _resending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds -= 1);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _verify([String? code]) async {
    if (_verifying) return;
    FocusScope.of(context).unfocus();

    final otp = code ?? _code;
    if (otp.length != _kOtpLength) {
      setState(() => _error = 'Kode OTP harus $_kOtpLength digit.');
      return;
    }

    setState(() {
      _error = null;
      _verifying = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(email: widget.email, otp: otp);
      if (!mounted) return;

      // authControllerProvider berubah -> AppRoot rebuild ke MainShell,
      // tapi layar ini nyampe ke sini lewat Navigator.push (dari RegisterForm
      // atau LoginForm), jadi tetap ada di atas stack sampai di-pop manual --
      // AppRoot rebuild di "belakang" tidak otomatis membuang route yang
      // ditumpuk di atasnya. Pop ke root supaya MainShell yang baru itu
      // kelihatan.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.isInvalidOtp
            ? 'Kode OTP salah atau sudah kedaluwarsa.'
            : error.message;
        // Kosongkan kotak-kotak biar gampang mengetik ulang, bukan harus
        // hapus manual satu-satu.
        _code = '';
        _boxesResetToken++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Tidak bisa memverifikasi kode. Coba lagi.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final message = await ref
          .read(authControllerProvider.notifier)
          .resendOtp(widget.email);
      if (!mounted) return;

      _startCooldown();
      showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Kode Terkirim',
        message: message,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppAlert(
        context,
        type: error.isThrottled ? AppAlertType.warning : AppAlertType.error,
        title: 'Gagal Mengirim Ulang',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Gagal Mengirim Ulang',
        message: 'Tidak bisa mengirim ulang kode OTP. Coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = !_resending && _cooldownSeconds <= 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Masukkan Kode OTP',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text.rich(
                TextSpan(
                  style: AppTypography.bodySmall,
                  children: [
                    const TextSpan(
                      text: 'Kami sudah mengirim kode $_kOtpLength digit ke ',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: '. Masukkan kode itu untuk mengaktifkan akunmu.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _OtpBoxInput(
                key: ValueKey(_boxesResetToken),
                length: _kOtpLength,
                enabled: !_verifying,
                hasError: _error != null,
                onChanged: (code) {
                  _code = code;
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: _verify,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Verifikasi',
                trailingIcon: null,
                isLoading: _verifying,
                onPressed: () => _verify(),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Kirim Ulang Kode (${_cooldownSeconds}s)'
                      : 'Kirim Ulang Kode',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Kembali',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkMuted,
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

/// Kotak-kotak input kode OTP (satu digit per kotak) — gantinya satu field
/// teks panjang. Mendukung ketik satu-satu (auto-pindah ke kotak berikutnya)
/// maupun tempel sekaligus (mis. salin kode dari email: sisa digitnya
/// otomatis tersebar ke kotak-kotak setelahnya).
class _OtpBoxInput extends StatefulWidget {
  const _OtpBoxInput({
    super.key,
    required this.length,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
  });

  final int length;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  State<_OtpBoxInput> createState() => _OtpBoxInputState();
}

class _OtpBoxInputState extends State<_OtpBoxInput> {
  late final _controllers = List.generate(
    widget.length,
    (_) => TextEditingController(),
  );
  late final _focusNodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onCompleted(code);
    }
  }

  /// Satu handler untuk dua kasus -- ketik satu digit maupun tempel banyak
  /// digit sekaligus -- karena keduanya sama-sama muncul lewat `onChanged`
  /// (baik lewat keyboard asli maupun `WidgetTester.enterText` di test).
  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      var cursor = index;
      for (final digit in digits.split('')) {
        if (cursor >= widget.length) break;
        _controllers[cursor].text = digit;
        cursor++;
      }
      _focusNodes[cursor.clamp(0, widget.length - 1)].requestFocus();
      _notify();
      return;
    }

    _controllers[index].text = digits;
    if (digits.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == widget.length - 1 ? 0 : AppSpacing.xs,
            ),
            child: AspectRatio(
              aspectRatio: 0.8,
              child: TextField(
                key: ValueKey('otp-box-$index'),
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: widget.enabled,
                autofocus: index == 0,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: widget.enabled
                      ? AppColors.background
                      : AppColors.background.withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.zero,
                  border: _border(AppColors.border),
                  enabledBorder: _border(
                    widget.hasError ? AppColors.danger : AppColors.border,
                  ),
                  focusedBorder: _border(
                    widget.hasError ? AppColors.danger : AppColors.primary,
                    width: 1.6,
                  ),
                ),
                onChanged: (value) => _handleChanged(index, value),
              ),
            ),
          ),
        );
      }),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
