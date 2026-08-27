import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/models/content/article_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/module_repository.dart';
import 'widgets/mark_complete_button.dart';
import 'widgets/module_header.dart';

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
  });

  final ModuleDetail module;
  final ModulePage page;

  @override
  ConsumerState<ArticleModuleScreen> createState() =>
      _ArticleModuleScreenState();
}

class _ArticleModuleScreenState extends ConsumerState<ArticleModuleScreen> {
  late bool _completed = widget.page.status.isCompleted;
  bool _busy = false;

  ArticleContent get _content =>
      (widget.page.content as ArticlePageContent).content;

  Future<void> _markComplete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(moduleRepositoryProvider)
          .completeModulePage(widget.page.id);
      if (mounted) setState(() => _completed = true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
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
      appBar: AppBar(title: Text(widget.module.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ModuleHeader(module: widget.module),
            const SizedBox(height: AppSpacing.lg),
            for (final block in blocks) ...[
              _ArticleBlockView(
                block: block,
                listItemNumber: listItemNumbers[block.id],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            MarkCompleteButton(
              completed: _completed,
              busy: _busy,
              onPressed: _markComplete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleBlockView extends StatelessWidget {
  const _ArticleBlockView({required this.block, this.listItemNumber});

  final ArticleBlock block;

  /// Cuma terisi untuk [ArticleBlockType.listItem] -- lihat perhitungannya
  /// di `_ArticleModuleScreenState.build`.
  final int? listItemNumber;

  @override
  Widget build(BuildContext context) {
    return switch (block.blockType) {
      ArticleBlockType.paragraph => Text(
        block.text ?? '',
        style: AppTypography.bodyLarge,
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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const AspectRatio(
                aspectRatio: 4 / 3,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, _, _) => AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: AppColors.background,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: AppTypography.bodyLarge),
          ),
        ),
      ],
    );
  }
}

class _ReferenceBlock extends StatelessWidget {
  const _ReferenceBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.link, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
