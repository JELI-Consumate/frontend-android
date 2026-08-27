import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.errorText,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.helperText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final String? errorText;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  /// Kalau `true`, field tidak menerima ketikan langsung — dipakai untuk
  /// field yang nilainya diisi lewat dialog lain, mis. date picker.
  final bool readOnly;

  /// Dipanggil saat field disentuh. Berguna bareng [readOnly] untuk
  /// membuka date picker atau dialog lain.
  final VoidCallback? onTap;

  /// Ikon tambahan di kanan field. Diabaikan kalau [obscure] `true`
  /// (slot itu dipakai tombol tampilkan/sembunyikan kata sandi).
  final IconData? suffixIcon;

  /// Catatan permanen di bawah field (mis. syarat kata sandi). Disembunyikan
  /// otomatis saat [errorText] terisi — sama seperti helper/error bawaan
  /// Material, supaya tidak dobel dengan pesan error.
  final String? helperText;

  /// Langsung fokus + buka keyboard begitu field ini muncul di layar --
  /// dipakai untuk field tunggal di bottom sheet (mis. ubah nama) supaya
  /// pengguna tidak perlu tap dulu.
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          onSubmitted: widget.onSubmitted,
          style: AppTypography.bodyMedium,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.muted,
            ),
            filled: true,
            fillColor: widget.enabled ? AppColors.white : AppColors.background,
            prefixIcon: Icon(widget.icon, size: 20, color: AppColors.muted),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    tooltip: _hidden
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                  )
                : widget.suffixIcon != null
                ? Icon(widget.suffixIcon, size: 20, color: AppColors.muted)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: _border(AppColors.border),
            enabledBorder: _border(
              hasError ? AppColors.danger : AppColors.border,
            ),
            focusedBorder: _border(
              hasError ? AppColors.danger : AppColors.primary,
              width: 1.6,
            ),
            disabledBorder: _border(AppColors.border),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xxs,
              left: AppSpacing.xxs,
            ),
            child: Text(
              widget.errorText!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          )
        else if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xxs,
              left: AppSpacing.xxs,
            ),
            child: Text(widget.helperText!, style: AppTypography.bodySmall),
          ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
