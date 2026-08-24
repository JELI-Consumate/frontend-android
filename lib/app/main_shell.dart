import 'package:flutter/material.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/learning/presentation/dashboard_screen.dart';
import '../features/learning/presentation/journeys_screen.dart';
import 'placeholder_tab_screen.dart';

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
    PlaceholderTabScreen(
      title: 'Pencapaian',
      message: 'Lencana dan indeks keberdayaanmu akan tampil di sini.',
      icon: Icons.emoji_events_outlined,
    ),
    HomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Perjalanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Pencapaian',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
