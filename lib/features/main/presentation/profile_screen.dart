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

/// Tab "Profil". Header identitas (avatar, nama, email) di atas kartu biru,
/// lalu informasi akun dalam baris-baris kartu putih di bawahnya.
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
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(authControllerProvider.notifier).refreshUser(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(user: user, onEditName: () => _editName(user.name)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informasi Akun', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: user.email,
                    trailing: _VerifiedBadge(verified: user.isEmailVerified),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.call_outlined,
                    label: 'Nomor HP',
                    value: user.phone ?? 'Belum diisi',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Tanggal Lahir',
                    value: user.dateOfBirth == null
                        ? 'Belum diisi'
                        : DateFormat(
                            'd MMMM y',
                            'id_ID',
                          ).format(user.dateOfBirth!),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Ubah Nama',
                    trailingIcon: Icons.edit_outlined,
                    isLoading: _busy,
                    onPressed: () => _editName(user.name),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _confirmSignOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Keluar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger),
                      ),
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

/// Bottom sheet ubah nama -- dulunya `AlertDialog`, ganti ke bottom sheet
/// supaya field-nya tidak ketutupan keyboard di layar kecil (dialog di
/// tengah layar mepet ke keyboard, sheet ini justru naik mengikutinya) dan
/// terasa lebih natural untuk aksi cepat sekali field begini di mobile.
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
      // Naik mengikuti tinggi keyboard supaya field-nya tidak ketutupan.
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

/// Garis kecil di puncak bottom sheet -- penanda visual umum bahwa ini
/// panel yang bisa ditutup swipe-down, bukan bagian dari layar utama.
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEditName});

  final AppUser user;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.card,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.white),
                  tooltip: 'Ubah nama',
                ),
              ),
              _Avatar(name: user.name, avatarUrl: user.avatarUrl),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user.name,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.white, width: 2.5),
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? Text(
                initial,
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.white,
                ),
              )
            : Image.network(
                avatarUrl!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  initial,
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelSmall),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
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
