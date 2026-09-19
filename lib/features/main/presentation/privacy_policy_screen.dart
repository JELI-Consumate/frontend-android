import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terakhir diperbarui: 19 September 2026',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '1. Pengumpulan Informasi',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami mengumpulkan informasi yang Anda berikan langsung kepada kami, seperti nama, alamat email, dan nomor telepon saat mendaftar. Kami juga dapat mengumpulkan data progres pembelajaran Anda agar sistem berfungsi dengan baik.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '2. Penggunaan Informasi',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Informasi yang dikumpulkan digunakan untuk:\n'
              '• Menyediakan, memelihara, dan meningkatkan layanan kami.\n'
              '• Melacak progres pembelajaran dan pencapaian (badges) Anda.\n'
              '• Berkomunikasi dengan Anda terkait pembaruan layanan Consumate.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '3. Perlindungan Informasi',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami mengutamakan keamanan data pribadi Anda dan menerapkan langkah-langkah keamanan secara teknis maupun organisasi untuk melindunginya dari akses, perubahan, atau pengungkapan yang tidak sah.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '4. Hubungi Kami',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini, silakan hubungi kami melalui email di tech@perlindungankonsumen.com.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
