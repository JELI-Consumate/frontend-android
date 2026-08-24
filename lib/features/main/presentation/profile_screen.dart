import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Terjadi kesalahan tak terduga. Coba lagi sebentar.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName(String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('Ubah nama', style: AppTypography.titleLarge),
        content: AppTextField(
          controller: controller,
          hintText: 'Nama lengkap',
          icon: Icons.person_outline,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName == null || newName.isEmpty || newName == currentName) return;

    await _run(() async {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(name: newName);
      _showMessage('Nama berhasil diperbarui.');
    });
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('Keluar dari akun?', style: AppTypography.titleLarge),
        content: Text(
          'Kamu perlu masuk lagi untuk melanjutkan belajar.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Keluar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _run(ref.read(authControllerProvider.notifier).signOut);
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
