import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../data/models/content/article_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/module_repository.dart';
import 'widgets/module_bottom_bar.dart';
import 'widgets/module_continue_button.dart';
import 'widgets/module_header.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_top_bar.dart';
import 'widgets/zoomable_image.dart';

/// Satu layar dipakai untuk EMPAT tipe module (`opening`, `materi`,
/// `infografis`, `komik`) -- keempatnya sama-sama `ContentableType::Article`
/// (deretan [ArticleBlock]), cuma beda dominasi jenis block: materi banyak
/// paragraph, infografis/komik banyak image. Bedanya cuma di chip tipe dari
/// [ModuleHeader], bukan di cara rendernya.
class ArticleModuleScreen extends ConsumerStatefulWidget {
  const ArticleModuleScreen({
    super.key,
    required this.module,
    required this.page,
    required this.nav,
  });

  final ModuleDetail module;
  final ModulePage page;
  final ModulePageNav nav;

  @override
  ConsumerState<ArticleModuleScreen> createState() =>
      _ArticleModuleScreenState();
}

class _ArticleModuleScreenState extends ConsumerState<ArticleModuleScreen> {
  late bool _completed = widget.page.status.isCompleted;
  bool _busy = false;

  ArticleContent get _content =>
      (widget.page.content as ArticlePageContent).content;

  /// Tandai selesai (kalau belum) lalu pindah ke halaman/module berikutnya
  /// lewat `widget.nav.onAdvance` -- SATU tombol untuk keduanya, dulu 2
  /// tombol terpisah ("Tandai Selesai" di sini + "Modul Selanjutnya" di
  /// footer luar).
  Future<void> _continue() async {
    if (!_completed) {
      final ok = await _markComplete();
      if (!ok || !mounted) return;
    }
    widget.nav.onAdvance();
  }

  Future<bool> _markComplete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(moduleRepositoryProvider)
          .completeModulePage(widget.page.id);
      if (mounted) setState(() => _completed = true);
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Menandai Selesai',
          message: error.message,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = [..._content.blocks]
      ..sort((a, b) => a.order.compareTo(b.order));

    // Nomor bullet dihitung cuma dari sesama block list_item, bukan dari
    // seluruh block campur tipe lain -- paragraph/gambar yang diselipkan di
    // antaranya tidak ikut menaikkan nomornya (sama seperti
    // `ArticleBlock::listItemNumber` di preview panel admin).
    var listItemCounter = 0;
    final listItemNumbers = <int, int>{};
    for (final block in blocks) {
      if (block.blockType == ArticleBlockType.listItem) {
        listItemCounter++;
        listItemNumbers[block.id] = listItemCounter;
      }
    }

    return Scaffold(
      appBar: ModuleTopBar(
        position: widget.nav.modulePosition,
        total: widget.nav.moduleTotal,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleHeader(module: widget.module),
              const SizedBox(height: AppSpacing.lg),
              ..._buildBlockWidgets(blocks, listItemNumbers),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ModuleBottomBar(
        pageCount: widget.nav.pageCount,
        pageIndex: widget.nav.pageIndex,
        onDotTap: widget.nav.onDotTap,
        child: ModuleContinueButton(
          hasNext: widget.nav.hasNext,
          busy: _busy,
          onPressed: _continue,
        ),
      ),
    );
  }

  /// Blok referensi dikelompokkan di bawah SATU heading "Referensi" begitu
  /// blok reference pertama ditemui -- gaya kutipan biasa (bukan lagi ikon
  /// tautan + italic per baris).
  List<Widget> _buildBlockWidgets(
    List<ArticleBlock> blocks,
    Map<int, int> listItemNumbers,
  ) {
    final widgets = <Widget>[];
    var referenceHeadingShown = false;

    for (final block in blocks) {
      final isReference = block.blockType == ArticleBlockType.reference;
      if (isReference && !referenceHeadingShown) {
        referenceHeadingShown = true;
        widgets
          ..add(Text('Referensi', style: AppTypography.titleSmall))
          ..add(const SizedBox(height: AppSpacing.xs));
      }

      widgets
        ..add(
          _ArticleBlockView(
            block: block,
            listItemNumber: listItemNumbers[block.id],
          ),
        )
        ..add(SizedBox(height: isReference ? AppSpacing.sm : AppSpacing.md));
    }

    return widgets;
  }
}

class _ArticleBlockView extends StatelessWidget {
  const _ArticleBlockView({required this.block, this.listItemNumber});

  final ArticleBlock block;

  /// Cuma terisi untuk [ArticleBlockType.listItem] -- lihat perhitungannya
  /// di `_ArticleModuleScreenState._buildBlockWidgets`.
  final int? listItemNumber;

  @override
  Widget build(BuildContext context) {
    return switch (block.blockType) {
      ArticleBlockType.paragraph => Text(
        block.text ?? '',
        style: AppTypography.bodyLarge,
        textAlign: TextAlign.justify,
      ),
      ArticleBlockType.image => _ImageBlock(block: block),
      ArticleBlockType.listItem => _ListItemBlock(
        number: listItemNumber ?? 1,
        text: block.text ?? '',
      ),
      ArticleBlockType.reference => _ReferenceBlock(text: block.text ?? ''),
      ArticleBlockType.unknown => const SizedBox.shrink(),
    };
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.block});

  final ArticleBlock block;

  @override
  Widget build(BuildContext context) {
    final url = block.imageUrl;
    if (url == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZoomableImage(
          url: url,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        if (block.altText case final altText? when altText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            altText,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ListItemBlock extends StatelessWidget {
  const _ListItemBlock({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        // Putih + border tipis -- BUKAN `AppColors.background` (itu persis
        // warna latar halaman artikel ini sendiri, jadi kotaknya kebentur tak
        // kelihatan sama sekali, lihat regresi yang dilaporkan). Border-nya
        // yang menjaga kotak ini tetap kelihatan meski warnanya putih sama
        // seperti latar, bukan cuma mengandalkan bedanya warna fill.
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        // Default (center) -- lingkaran nomornya ikut di-tengahkan kalau
        // teksnya sampai 2 baris (mis. "Menjadi konsumen yang cerdas,
        // bijak, dan bertanggung jawab."), bukan nempel rata atas.
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Solid, bukan `primarySoft` -- biar lingkarannya tetap kontras
              // menonjol di atas kotak putih di sekelilingnya.
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris referensi tunggal -- teks polos rata kiri (bukan lagi ikon tautan +
/// italic), dikumpulkan di bawah heading "Referensi" (lihat
/// `_ArticleModuleScreenState._buildBlockWidgets`).
class _ReferenceBlock extends StatelessWidget {
  const _ReferenceBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.bodySmall);
  }
}
