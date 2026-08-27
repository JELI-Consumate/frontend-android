import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/module_detail.dart';
import 'models/quiz_attempt.dart';
import 'models/simulation_attempt.dart';
import 'models/content/reflection_content.dart';

class ModuleRepository {
  ModuleRepository(this._dio);

  final Dio _dio;

  /// `GET /modules/{id}` -- module + seluruh halaman + konten polimorfiknya
  /// sudah ter-resolve dalam satu panggilan (lihat `ContentTreeService` di
  /// backend, eager load semuanya sekaligus).
  Future<ModuleDetail> module(int moduleId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/modules/$moduleId',
      );
      return ModuleDetail.fromJson(_requireData(response.data));
    });
  }

  /// Modul pasif (opening/materi/infografis/komik/video) tidak punya
  /// mekanisme "selesai otomatis" di server seperti kuis/simulasi/refleksi
  /// -- harus ditandai eksplisit lewat endpoint ini begitu user menuntaskan
  /// bacaan/tontonannya.
  Future<void> completeModulePage(int modulePageId) {
    return guardApi(() async {
      await _dio.post<Map<String, dynamic>>(
        '/module-pages/$modulePageId/complete',
      );
    });
  }

  /// `POST /quizzes/{id}/attempts` -- selalu membuat attempt baru, tidak ada
  /// batas jumlah percobaan untuk kuis journey (BR-06 di backend).
  Future<int> startQuizAttempt(int quizContentId) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quizzes/$quizContentId/attempts',
      );
      final data = _requireData(response.data);
      return (data['attempt_id'] as num).toInt();
    });
  }

  /// [choiceAnswers]: `quiz_question_id -> quiz_choice_option_id` yang
  /// dipilih user. [likertAnswers]: `quiz_question_id -> likert_scale_option_id`.
  /// Backend menandai halaman ini selesai begitu attempt disubmit, apapun
  /// hasilnya (lihat `QuizScoringService::submit`).
  Future<QuizAttempt> submitQuizAttempt({
    required int attemptId,
    required Map<int, int> choiceAnswers,
    required Map<int, int> likertAnswers,
  }) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quiz-attempts/$attemptId/submit',
        data: {
          'choice_answers': [
            for (final entry in choiceAnswers.entries)
              {
                'quiz_question_id': entry.key,
                'quiz_choice_option_id': entry.value,
              },
          ],
          'likert_answers': [
            for (final entry in likertAnswers.entries)
              {
                'quiz_question_id': entry.key,
                'likert_scale_option_id': entry.value,
              },
          ],
        },
      );
      return QuizAttempt.fromJson(_requireData(response.data));
    });
  }

  /// `POST /simulations/{id}/attempts` -- selalu attempt baru tiap kali
  /// simulasi dibuka (tidak ada riwayat attempt yang di-resume di API ini).
  Future<int> startSimulationAttempt(int simulationContentId) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulations/$simulationContentId/attempts',
      );
      final data = _requireData(response.data);
      return (data['attempt_id'] as num).toInt();
    });
  }

  /// Cek satu pasangan game `matching` -- gaya Duolingo: SATU request per
  /// percobaan, jawaban salah tidak disimpan jadi boleh dicoba lagi.
  Future<SimulationCheckResult> checkMatchingAnswer({
    required int attemptId,
    required int pairId,
    required int submittedRightPairId,
  }) {
    return _checkSimulationAnswer(attemptId, {
      'type': 'matching',
      'simulation_matching_pair_id': pairId,
      'submitted_right_pair_id': submittedRightPairId,
    });
  }

  /// Cek satu langkah game `ordering` di posisi [submittedPosition]
  /// (1-based -- lihat `CheckSimulationAnswerRequest` di backend: `min:1`).
  Future<SimulationCheckResult> checkOrderingAnswer({
    required int attemptId,
    required int stepId,
    required int submittedPosition,
  }) {
    return _checkSimulationAnswer(attemptId, {
      'type': 'ordering',
      'simulation_ordering_step_id': stepId,
      'submitted_position': submittedPosition,
    });
  }

  Future<SimulationCheckResult> _checkSimulationAnswer(
    int attemptId,
    Map<String, dynamic> data,
  ) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulation-attempts/$attemptId/check',
        data: data,
      );
      return SimulationCheckResult.fromJson(_requireData(response.data));
    });
  }

  /// `GET /reflections/{id}` -- BEDA dari konten refleksi yang ikut terbawa
  /// `GET /modules/{id}`: endpoint ini (`ReflectionDetailResource`) sudah
  /// digabung dengan jawaban tersimpan user (`answer_text`/`is_checked`),
  /// yang tidak pernah disertakan di respons module tree.
  Future<ReflectionContent> reflection(int reflectionContentId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reflections/$reflectionContentId',
      );
      return ReflectionContent.fromJson(_requireData(response.data));
    });
  }

  /// [answers]: `reflection_question_id -> jawaban teks` (open_question).
  /// [checklistAnswers]: `reflection_checklist_item_id -> tercentang?`.
  /// Selalu kirim seluruh state form saat ini (bukan cuma yang berubah) --
  /// upsert-nya idempotent di backend jadi aman dipanggil berulang.
  Future<ReflectionContent> saveReflectionEntries({
    required int reflectionContentId,
    required Map<int, String> answers,
    required Map<int, bool> checklistAnswers,
  }) {
    return guardApi(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/reflections/$reflectionContentId/entries',
        data: {
          'entries': [
            for (final entry in answers.entries)
              {'reflection_question_id': entry.key, 'answer_text': entry.value},
          ],
          'checklist_answers': [
            for (final entry in checklistAnswers.entries)
              {
                'reflection_checklist_item_id': entry.key,
                'is_checked': entry.value,
              },
          ],
        },
      );
      return ReflectionContent.fromJson(_requireData(response.data));
    });
  }

  Map<String, dynamic> _requireData(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons server tidak dikenali.');
    }
    return data;
  }
}

final moduleRepositoryProvider = Provider<ModuleRepository>((ref) {
  return ModuleRepository(ref.watch(dioProvider));
});
