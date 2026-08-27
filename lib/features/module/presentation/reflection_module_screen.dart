import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/reflection_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/module_repository.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_header.dart';

/// Modul tipe `refleksi` -- jurnal tanpa skor benar/salah (BR-10). Selesai
/// otomatis di server begitu SEMUA pertanyaan `open_question` terisi
/// (checklist tidak menghalangi selesai) -- lihat `ReflectionService`.
///
/// Kontennya diambil dari `GET /reflections/{id}`, BUKAN dari
/// `GET /modules/{id}` -- respons module tree tidak membawa jawaban
/// tersimpan user (lihat `ModuleRepository.reflection`).
class ReflectionModuleScreen extends ConsumerStatefulWidget {
  const ReflectionModuleScreen({
    super.key,
    required this.module,
    required this.page,
  });

  final ModuleDetail module;
  final ModulePage page;

  @override
  ConsumerState<ReflectionModuleScreen> createState() =>
      _ReflectionModuleScreenState();
}

class _ReflectionModuleScreenState
    extends ConsumerState<ReflectionModuleScreen> {
  ReflectionContent? _content;
  ApiException? _loadError;
  bool _saving = false;

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _checklist = {};

  int get _reflectionId =>
      (widget.page.content as ReflectionPageContent).content.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final content = await ref
          .read(moduleRepositoryProvider)
          .reflection(_reflectionId);
      _hydrate(content);
      if (mounted) setState(() => _content = content);
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  /// Isi controller/checklist dari [content] TANPA menimpa yang sudah ada --
  /// dipanggil ulang tiap kali dapat konten segar (muat awal maupun setelah
  /// simpan) supaya teks yang baru saja diketik user tidak hilang.
  void _hydrate(ReflectionContent content) {
    for (final section in content.sections) {
      for (final question in section.questions) {
        if (question.questionType == ReflectionQuestionType.openQuestion) {
          _controllers.putIfAbsent(
            question.id,
            () => TextEditingController(text: question.answerText ?? ''),
          );
        }
        for (final item in question.checklistItems) {
          _checklist.putIfAbsent(item.id, () => item.isChecked);
        }
      }
    }
  }

  bool get _isComplete {
    final content = _content;
    if (content == null) return false;
    final openQuestions = content.openQuestions;
    if (openQuestions.isEmpty) return true;
    return openQuestions.every(
      (question) =>
          (_controllers[question.id]?.text.trim().isNotEmpty ?? false),
    );
  }

  Future<void> _save() async {
    final content = _content;
    if (content == null) return;

    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(moduleRepositoryProvider)
          .saveReflectionEntries(
            reflectionContentId: content.id,
            answers: {
              for (final entry in _controllers.entries)
                entry.key: entry.value.text.trim(),
            },
            checklistAnswers: Map.of(_checklist),
          );
      if (mounted) {
        setState(() => _content = updated);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Jawaban tersimpan.')));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return ModuleErrorScaffold(
        title: widget.module.title,
        message: _loadError!.message,
      );
    }
    final content = _content;
    if (content == null) return const ModuleLoadingScaffold();

    final openQuestions = content.openQuestions;
    final answeredCount = openQuestions
        .where((q) => (_controllers[q.id]?.text.trim().isNotEmpty ?? false))
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ModuleHeader(module: widget.module),
            const SizedBox(height: AppSpacing.sm),
            _MessageCard(
              icon: Icons.auto_stories_outlined,
              color: AppColors.primary,
              text: content.openingMessage,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final section in [
              ...content.sections,
            ]..sort((a, b) => a.order.compareTo(b.order))) ...[
              _SectionView(
                section: section,
                controllers: _controllers,
                checklist: _checklist,
                onChecklistToggled: (itemId, value) =>
                    setState(() => _checklist[itemId] = value),
                onAnswerChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (openQuestions.isNotEmpty) ...[
              Text(
                '$answeredCount/${openQuestions.length} pertanyaan terisi',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            PrimaryButton(
              label: 'Simpan Jawaban',
              trailingIcon: Icons.save_outlined,
              isLoading: _saving,
              onPressed: _save,
            ),
            if (content.closingMessage case final closingMessage?
                when _isComplete) ...[
              const SizedBox(height: AppSpacing.lg),
              _MessageCard(
                icon: Icons.emoji_events_outlined,
                color: AppColors.success,
                title: content.closingTitle,
                text: closingMessage,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({
    required this.section,
    required this.controllers,
    required this.checklist,
    required this.onChecklistToggled,
    required this.onAnswerChanged,
  });

  final ReflectionSection section;
  final Map<int, TextEditingController> controllers;
  final Map<int, bool> checklist;
  final void Function(int itemId, bool value) onChecklistToggled;
  final VoidCallback onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: AppTypography.titleLarge),
        if (section.instruction case final instruction?) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(instruction, style: AppTypography.bodySmall),
        ],
        const SizedBox(height: AppSpacing.sm),
        for (final question in [
          ...section.questions,
        ]..sort((a, b) => a.order.compareTo(b.order))) ...[
          _QuestionView(
            question: question,
            controllers: controllers,
            checklist: checklist,
            onChecklistToggled: onChecklistToggled,
            onAnswerChanged: onAnswerChanged,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.question,
    required this.controllers,
    required this.checklist,
    required this.onChecklistToggled,
    required this.onAnswerChanged,
  });

  final ReflectionQuestion question;
  final Map<int, TextEditingController> controllers;
  final Map<int, bool> checklist;
  final void Function(int itemId, bool value) onChecklistToggled;
  final VoidCallback onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (question.questionType == ReflectionQuestionType.checklist)
          for (final item in [
            ...question.checklistItems,
          ]..sort((a, b) => a.order.compareTo(b.order)))
            _ChecklistRow(
              label: item.label,
              checked: checklist[item.id] ?? false,
              onChanged: (value) => onChecklistToggled(item.id, value),
            )
        else
          _JournalField(
            controller: controllers[question.id],
            onChanged: onAnswerChanged,
          ),
      ],
    );
  }
}

class _JournalField extends StatelessWidget {
  const _JournalField({required this.controller, required this.onChanged});

  final TextEditingController? controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      minLines: 3,
      maxLines: 6,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Tulis jawabanmu di sini...',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.color,
    required this.text,
    this.title,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title case final title?) ...[
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(text, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
