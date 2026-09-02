import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/module_detail.dart';
import 'models/quiz_attempt.dart';
import 'models/simulation_attempt.dart';
import 'models/content/quiz_content.dart';
import 'models/content/reflection_content.dart';

class ModuleRepository {
  ModuleRepository(this._dio);

  final Dio _dio;

  Future<ModuleDetail> module(String moduleId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/modules/$moduleId',
      );
      return ModuleDetail.fromJson(_requireData(response.data));
    });
  }

  Future<void> completeModulePage(String modulePageId) {
    return guardApi(() async {
      await _dio.post<Map<String, dynamic>>(
        '/module-pages/$modulePageId/complete',
      );
    });
  }

  Future<String> startQuizAttempt(String quizContentId) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quizzes/$quizContentId/attempts',
      );
      final data = _requireData(response.data);
      return data['attempt_id'] as String;
    });
  }

  Future<QuizAnswerCheckResult> checkQuizAnswer({
    required String attemptId,
    required String questionId,
    required QuizSegmentType type,
    String? choiceOptionId,
    String? likertOptionId,
  }) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quiz-attempts/$attemptId/check',
        data: {
          'type': type == QuizSegmentType.likert ? 'likert' : 'multiple_choice',
          'quiz_question_id': questionId,
          'quiz_choice_option_id': ?choiceOptionId,
          'likert_scale_option_id': ?likertOptionId,
        },
      );
      return QuizAnswerCheckResult.fromJson(_requireData(response.data));
    });
  }

  Future<String> startSimulationAttempt(String simulationContentId) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulations/$simulationContentId/attempts',
      );
      final data = _requireData(response.data);
      return data['attempt_id'] as String;
    });
  }

  Future<SimulationCheckResult> checkMatchingAnswer({
    required String attemptId,
    required String pairId,
    required String submittedRightPairId,
  }) {
    return _checkSimulationAnswer(attemptId, {
      'type': 'matching',
      'simulation_matching_pair_id': pairId,
      'submitted_right_pair_id': submittedRightPairId,
    });
  }

  Future<SimulationCheckResult> checkOrderingAnswer({
    required String attemptId,
    required String stepId,
    required int submittedPosition,
  }) {
    return _checkSimulationAnswer(attemptId, {
      'type': 'ordering',
      'simulation_ordering_step_id': stepId,
      'submitted_position': submittedPosition,
    });
  }

  Future<SimulationCheckResult> _checkSimulationAnswer(
    String attemptId,
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

  Future<ReflectionContent> reflection(String reflectionContentId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reflections/$reflectionContentId',
      );
      return ReflectionContent.fromJson(_requireData(response.data));
    });
  }

  Future<ReflectionContent> saveReflectionEntries({
    required String reflectionContentId,
    required Map<String, String> answers,
    required Map<String, bool> checklistAnswers,
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
