import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/application/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perlindungan Konsumen'),
        actions: [
          IconButton(
            onPressed: _busy
                ? null
                : () => _run(
                    ref.read(authControllerProvider.notifier).refreshUser,
                  ),
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang profil',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Halo, ${user.name}!', style: AppTypography.displaySmall),
              const SizedBox(height: AppSpacing.lg),
              _InfoTile(label: 'Email', value: user.email),
              _InfoTile(label: 'Nomor HP', value: user.phone ?? '-'),
              _InfoTile(
                label: 'Tanggal lahir',
                value: user.dateOfBirth == null
                    ? '-'
                    : user.dateOfBirth!.toIso8601String().substring(0, 10),
              ),
              _InfoTile(
                label: 'Email terverifikasi',
                value: user.isEmailVerified ? 'Sudah' : 'Belum',
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Ubah nama',
                trailingIcon: null,
                isLoading: _busy,
                onPressed: () => _editName(user.name),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        ref.read(authControllerProvider.notifier).signOut,
                      ),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
