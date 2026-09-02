import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/app_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  void _showSuccess(String message) {
    if (!mounted) return;
    showAppAlert(
      context,
      type: AppAlertType.success,
      title: 'Berhasil',
      message: message,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    showAppAlert(
      context,
      type: AppAlertType.error,
      title: 'Terjadi Kesalahan',
      message: message,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Terjadi kesalahan tak terduga. Coba lagi sebentar.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName(String currentName) async {
    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditNameSheet(currentName: currentName),
    );

    if (newName == null || newName.isEmpty || newName == currentName) return;

    await _run(() async {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(name: newName);
      _showSuccess('Nama berhasil diperbarui.');
    });
  }

  Future<void> _editBirthDate(DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || picked == current) return;

    await _run(() async {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(dateOfBirth: picked);
      _showSuccess('Tanggal lahir berhasil diperbarui.');
    });
  }

  void _notifyPhotoUploadUnavailable() {
    showAppAlert(
      context,
      type: AppAlertType.info,
      title: 'Segera Hadir',
      message: 'Fitur ganti foto profil belum tersedia saat ini.',
    );
  }

  Future<void> _confirmSignOut() async {
    await showAppAlert(
      context,
      type: AppAlertType.warning,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk lagi untuk melanjutkan belajar.',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      onConfirm: () => _run(ref.read(authControllerProvider.notifier).signOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(authControllerProvider.notifier).refreshUser(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              user: user,
              onTapAvatar: _notifyPhotoUploadUnavailable,
              onTapName: _busy ? null : () => _editName(user.name),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xl,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileField(
                    label: 'Email',
                    value: user.email,
                    trailing: _VerifiedBadge(verified: user.isEmailVerified),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileField(
                    label: 'Nomor HP',
                    value: user.phone,
                    placeholder: 'Belum diisi',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileField(
                    label: 'Tanggal Lahir',
                    value: user.dateOfBirth == null
                        ? null
                        : DateFormat('dd-MM-yyyy').format(user.dateOfBirth!),
                    placeholder: 'Pilih tanggal lahir',
                    trailing: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    onTap: _busy
                        ? null
                        : () => _editBirthDate(user.dateOfBirth),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _LogoutPillButton(
                      busy: _busy,
                      onPressed: _busy ? null : _confirmSignOut,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.currentName});

  final String currentName;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final _controller = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String trimmed) {
    if (trimmed.isEmpty || trimmed == widget.currentName) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _SheetDragHandle()),
                const SizedBox(height: AppSpacing.md),
                Text('Ubah Nama', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Nama ini akan tampil di profil dan sertifikatmu.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _controller,
                  hintText: 'Nama lengkap',
                  icon: Icons.person_outline,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _submit(value.trim()),
                ),
                const SizedBox(height: AppSpacing.lg),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final trimmed = value.text.trim();
                    final canSubmit =
                        trimmed.isNotEmpty && trimmed != widget.currentName;
                    return PrimaryButton(
                      label: 'Simpan',
                      trailingIcon: Icons.check,
                      onPressed: canSubmit ? () => _submit(trimmed) : null,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

const double _kHeaderCurveRadius = 64;

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onTapAvatar,
    required this.onTapName,
  });

  final AppUser user;
  final VoidCallback onTapAvatar;
  final VoidCallback? onTapName;

  @override
  Widget build(BuildContext context) {
    const curve = BorderRadius.vertical(
      bottom: Radius.circular(_kHeaderCurveRadius),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: curve,
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: curve,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryPressed],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  _AvatarWithCameraBadge(
                    name: user.name,
                    avatarUrl: user.avatarUrl,
                    onTapCamera: onTapAvatar,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: onTapName,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTapName != null) ...[
                            const SizedBox(width: AppSpacing.xxs),
                            Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppColors.white.withValues(alpha: 0.8),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarWithCameraBadge extends StatelessWidget {
  const _AvatarWithCameraBadge({
    required this.name,
    required this.avatarUrl,
    required this.onTapCamera,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onTapCamera;

  static const double _size = 132;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.16),
              border: Border.all(color: AppColors.white, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.white,
                      ),
                    )
                  : Image.network(
                      avatarUrl!,
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Text(
                        initial,
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapCamera,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 17,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    this.placeholder,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : (placeholder ?? '-'),
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasValue ? AppColors.ink : AppColors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(height: 1, color: AppColors.border),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: content,
    );
  }
}

class _LogoutPillButton extends StatelessWidget {
  const _LogoutPillButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : const Icon(Icons.logout, size: 18),
      label: const Text('Keluar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : AppColors.warning;
    final softColor = verified ? AppColors.successSoft : AppColors.warningSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.error_outline,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            verified ? 'Aktif' : 'Belum',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
