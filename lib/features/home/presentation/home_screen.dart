import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perlindungan Konsumen'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Skeleton project siap.\n\n'
            'Mulai bangun fitur di lib/features/, '
            'dan sambungkan ke REST API lewat '
            'lib/core/network/api_client.dart.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
