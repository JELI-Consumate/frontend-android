import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/reflection_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/module_repository.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_page_scaffold.dart';

class ReflectionModuleScreen extends ConsumerStatefulWidget {
  const ReflectionModuleScreen({
    super.key,
    required this.module,
    required this.page,
    required this.nav,
  });

  final ModuleDetail module;
  final ModulePage page;
  final ModulePageNav nav;

  @override
  ConsumerState<ReflectionModuleScreen> createState() =>
      _ReflectionModuleScreenState();
}

class _ReflectionModuleScreenState
    extends ConsumerState<ReflectionModuleScreen> {
  ReflectionContent? _content;
  ApiException? _loadError;
  bool _saving = false;

  late bool _savedComplete = widget.page.status.isCompleted;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _checklist = {};

  String get _reflectionId =>
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

  Future<bool> _save() async {
    final content = _content;
    if (content == null) return false;

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
        setState(() {
          _content = updated;
          if (_isComplete) _savedComplete = true;
        });
        showAppAlert(
          context,
          type: AppAlertType.success,
          title: 'Berhasil',
          message: 'Jawaban tersimpan.',
        );
      }
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Menyimpan',
          message: error.message,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _continue() async {
    final ok = await _save();
    if (!ok || !mounted) return;
    widget.nav.onAdvance();
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

    return ModulePageScaffold(
      nav: widget.nav,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in [
              ...content.sections,
            ]..sort((a, b) => a.order.compareTo(b.order))) ...[
              _SectionCard(
                section: section,
                controllers: _controllers,
                checklist: _checklist,
                onChecklistToggled: (itemId, value) =>
                    setState(() => _checklist[itemId] = value),
                onAnswerChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (content.closingMessage case final closingMessage?
                when _isComplete) ...[
              Text(
                content.closingTitle ?? 'Kata Penutup',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                closingMessage,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.justify,
              ),
            ],
          ],
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_savedComplete && openQuestions.isNotEmpty) ...[
            Text(
              '$answeredCount/${openQuestions.length} pertanyaan terisi',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          PrimaryButton(
            label: _savedComplete
                ? (widget.nav.hasNext ? 'Selanjutnya' : 'Selesai')
                : 'Simpan Jawaban',
            trailingIcon: _savedComplete
                ? (widget.nav.hasNext ? Icons.arrow_forward : Icons.check)
                : Icons.save_outlined,
            isLoading: _saving,
            onPressed: _savedComplete ? _continue : _save,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.controllers,
    required this.checklist,
    required this.onChecklistToggled,
    required this.onAnswerChanged,
  });

  final ReflectionSection section;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checklist;
  final void Function(String itemId, bool value) onChecklistToggled;
  final VoidCallback onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final isChecklistSection = section.questions.any(
      (question) => question.questionType == ReflectionQuestionType.checklist,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionIcon(isChecklist: isChecklistSection),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(section.title, style: AppTypography.titleLarge),
                ),
              ),
            ],
          ),
          if (section.instruction case final instruction?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(instruction, style: AppTypography.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
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
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.isChecklist});

  final bool isChecklist;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isChecklist ? AppColors.background : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        isChecklist ? Icons.checklist_outlined : Icons.edit_note,
        color: isChecklist ? AppColors.ink : AppColors.white,
        size: 22,
      ),
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
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checklist;
  final void Function(String itemId, bool value) onChecklistToggled;
  final VoidCallback onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: AppTypography.bodyLarge,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (question.questionType == ReflectionQuestionType.checklist)
          for (final item in [
            ...question.checklistItems,
          ]..sort((a, b) => a.order.compareTo(b.order))) ...[
            _ChecklistRow(
              label: item.label,
              checked: checklist[item.id] ?? false,
              onChanged: (value) => onChecklistToggled(item.id, value),
            ),
            const SizedBox(height: AppSpacing.sm),
          ]
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
        hintText: 'Tulis pendapatmu di sini...',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
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
      color: AppColors.background,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: checked,
                    onChanged: (value) => onChanged(value ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }
}
