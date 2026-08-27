import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/badges/presentation/badges_screen.dart';
import '../features/main/presentation/dashboard_screen.dart';
import '../features/main/presentation/journeys_screen.dart';
import '../features/main/presentation/profile_screen.dart';

/// Rangka navigasi utama setelah login: empat tab di bawah, masing-masing
/// Scaffold sendiri. `IndexedStack` menjaga state tiap tab tetap hidup saat
/// pindah-pindah (mis. posisi scroll di Perjalanan tidak reset ke atas
/// waktu balik dari tab lain).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    JourneysScreen(),
    BadgesScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NavItemData(icon: Icons.home_rounded, label: 'Beranda'),
    _NavItemData(icon: Icons.auto_stories_rounded, label: 'Perjalanan'),
    _NavItemData(icon: Icons.workspace_premium_rounded, label: 'Pencapaian'),
    _NavItemData(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _BottomNavBar(
        items: _items,
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bar navigasi bawah custom -- bukan `NavigationBar` bawaan Material.
/// Bedanya dari default Material 3: tab aktif ditandai garis kecil di ATAS
/// ikon (bukan pil/latar biru di belakang ikon), dan pemisah dari konten di
/// atasnya berupa shadow tipis (lihat AppShadows.navBar), bukan border.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: AppShadows.navBar,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          // Garis indikator tab aktif, nempel pas di tepi paling atas bar.
          // Cuma digambar kalau tab ini aktif -- bukan kotak transparan yang
          // selalu ada di baliknya -- supaya tab yang tidak aktif benar-benar
          // tidak menggambar apa pun di situ (kotak transparan yang "selalu
          // ada" sebelumnya meninggalkan garis samar di atas ikon).
          if (selected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIcon(icon: data.icon, selected: selected),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  data.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected ? AppColors.primary : AppColors.inkMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikon tab bawah pakai `Icon` bawaan Flutter (font glyph), bukan PNG lagi --
/// PNG kustom sebelumnya selalu ada garis samar di tepinya waktu di-scale +
/// di-tint (artefak rendering bitmap), sedangkan glyph font digambar
/// vector/langsung di warna yang diminta tanpa proses scale+tint bitmap,
/// jadi tidak kena masalah itu sama sekali.
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 24,
      color: selected ? AppColors.primary : AppColors.inkMuted,
    );
  }
}
