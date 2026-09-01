import 'package:flutter/foundation.dart';

/// Cermin dari `SimulationType` enum di backend.
enum SimulationGameType {
  matching,
  ordering,
  unknown;

  static SimulationGameType fromJson(Object? value) {
    return switch (value) {
      'matching' => SimulationGameType.matching,
      'ordering' => SimulationGameType.ordering,
      _ => SimulationGameType.unknown,
    };
  }
}

@immutable
class SimulationMatchingPair {
  const SimulationMatchingPair({
    required this.id,
    required this.leftLabel,
    required this.leftDescription,
    required this.leftImageUrl,
    required this.rightLabel,
    required this.rightDescription,
    required this.rightImageUrl,
    required this.order,
  });

  final String id;
  final String leftLabel;
  final String? leftDescription;
  final String? leftImageUrl;
  final String rightLabel;
  final String? rightDescription;
  final String? rightImageUrl;
  final int order;

  factory SimulationMatchingPair.fromJson(Map<String, dynamic> json) {
    return SimulationMatchingPair(
      id: json['id'] as String,
      leftLabel: json['left_label'] as String,
      leftDescription: json['left_description'] as String?,
      leftImageUrl: json['left_image_url'] as String?,
      rightLabel: json['right_label'] as String,
      rightDescription: json['right_description'] as String?,
      rightImageUrl: json['right_image_url'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class SimulationOrderingStep {
  const SimulationOrderingStep({
    required this.id,
    required this.label,
    required this.imageUrl,
    required this.order,
  });

  final String id;
  final String label;
  final String? imageUrl;

  /// Urutan tampil di response (`array_key` datang), BUKAN `correct_position`
  /// -- backend sengaja tidak pernah mengirim posisi yang benar (lihat
  /// `SimulationContentResource`), itu dijaga di server dan cuma dicek lewat
  /// `POST /simulation-attempts/{id}/check`.
  final int order;

  factory SimulationOrderingStep.fromJson(Map<String, dynamic> json) {
    return SimulationOrderingStep(
      id: json['id'] as String,
      label: json['label'] as String,
      imageUrl: json['image_url'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Konten tipe `simulation` (`ContentableType::Simulation`) -- salah satu
/// dari dua game: [SimulationGameType.matching] (pasangkan kartu kiri-kanan)
/// atau [SimulationGameType.ordering] (susun langkah sesuai urutan benar).
@immutable
class SimulationContent {
  const SimulationContent({
    required this.id,
    required this.title,
    required this.simulationType,
    required this.scenario,
    required this.matchingPairs,
    required this.orderingSteps,
  });

  final String id;
  final String title;
  final SimulationGameType simulationType;
  final String scenario;
  final List<SimulationMatchingPair> matchingPairs;
  final List<SimulationOrderingStep> orderingSteps;

  factory SimulationContent.fromJson(Map<String, dynamic> json) {
    final rawPairs = json['matching_pairs'];
    final rawSteps = json['ordering_steps'];
    return SimulationContent(
      id: json['id'] as String,
      title: json['title'] as String,
      simulationType: SimulationGameType.fromJson(json['simulation_type']),
      scenario: json['scenario'] as String? ?? '',
      matchingPairs: rawPairs is List
          ? rawPairs
                .cast<Map<String, dynamic>>()
                .map(SimulationMatchingPair.fromJson)
                .toList()
          : const [],
      orderingSteps: rawSteps is List
          ? rawSteps
                .cast<Map<String, dynamic>>()
                .map(SimulationOrderingStep.fromJson)
                .toList()
          : const [],
    );
  }
}
