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
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami mengumpulkan informasi yang Anda berikan langsung kepada kami, seperti nama, alamat email, dan nomor telepon saat Anda mendaftar atau membuat akun. Kami juga secara otomatis mengumpulkan data aktivitas dan progres pembelajaran Anda di dalam aplikasi agar sistem dapat berfungsi dengan baik.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '2. Penggunaan Informasi',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Informasi yang kami kumpulkan digunakan untuk tujuan berikut:\n'
              '• Menyediakan, memelihara, dan meningkatkan kualitas layanan Consumate.\n'
              '• Melacak progres pembelajaran dan memberikan pencapaian (badges) kepada Anda.\n'
              '• Berkomunikasi dengan Anda terkait dukungan teknis, keamanan, dan pembaruan layanan.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '3. Pembagian Data dengan Pihak Ketiga',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami sangat menghargai privasi Anda dan tidak menjual data pribadi Anda kepada siapa pun. Kami hanya membagikan informasi Anda kepada vendor atau penyedia layanan pihak ketiga (misalnya layanan cloud hosting atau pengelola server) yang secara langsung membantu operasional layanan kami. Pihak ketiga ini terikat oleh kewajiban ketat untuk menjaga kerahasiaan dan keamanan data Anda.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '4. Masa Penyimpanan Data',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Data pribadi Anda akan kami simpan selama akun Anda aktif atau selama diperlukan untuk menyediakan layanan kepada Anda. Apabila Anda memutuskan untuk berhenti menggunakan layanan dan menghapus akun, kami akan menghapus atau menganonimkan data pribadi Anda dari sistem kami sesuai dengan peraturan perundang-undangan yang berlaku.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '5. Perlindungan Informasi',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami mengutamakan keamanan data pribadi Anda. Kami menerapkan langkah-langkah keamanan secara teknis maupun organisasi yang wajar untuk melindungi data Anda dari akses, perubahan, kehilangan, atau pengungkapan yang tidak sah oleh pihak yang tidak bertanggung jawab.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '6. Penggunaan Cookies dan Teknologi Pelacakan',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami mungkin menggunakan cookies atau teknologi serupa untuk mengenali sesi login Anda, mengingat preferensi Anda, dan meningkatkan pengalaman penggunaan aplikasi. Anda dapat mengatur atau menolak cookies melalui pengaturan perangkat atau browser Anda.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '7. Hak Anda atas Data Pribadi',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Anda memiliki kendali penuh atas data pribadi Anda. Anda berhak untuk:\n'
              '• Mengakses dan melihat data pribadi yang kami simpan tentang Anda.\n'
              '• Memperbarui atau mengoreksi data yang tidak akurat.\n'
              '• Meminta penghapusan data pribadi Anda atau menghapus akun Anda secara permanen.\n\n'
              'Permintaan terkait hak ini dapat dilakukan melalui menu pengaturan di dalam aplikasi atau dengan menghubungi kami secara langsung.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '8. Perubahan pada Kebijakan Privasi',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu untuk menyesuaikan dengan layanan kami atau peraturan hukum yang baru. Jika terdapat perubahan yang signifikan, kami akan memberikan pemberitahuan kepada Anda melalui aplikasi atau email sebelum pembaruan tersebut diberlakukan.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              '9. Hubungi Kami',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Jika Anda memiliki pertanyaan, masukan, atau ingin menggunakan hak Anda terkait Kebijakan Privasi ini, silakan hubungi kami melalui email di: consumate.id@gmail.com.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
