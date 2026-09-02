import 'package:flutter/foundation.dart';

@immutable
class Badge {
  const Badge({
    required this.id,
    required this.journeyId,
    required this.name,
    required this.description,
    required this.congratulationMessage,
    required this.motivationalMessage,
    required this.iconUrl,
    required this.earned,
    required this.earnedAt,
  });

  final String id;

  final String journeyId;
  final String name;
  final String description;

  final String? congratulationMessage;
  final String? motivationalMessage;
  final String? iconUrl;
  final bool earned;

  final DateTime? earnedAt;

  factory Badge.fromJson(Map<String, dynamic> json) {
    final rawEarnedAt = json['earned_at'];
    return Badge(
      id: json['id'] as String,
      journeyId: json['journey_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      congratulationMessage: json['congratulation_message'] as String?,
      motivationalMessage: json['motivational_message'] as String?,
      iconUrl: json['icon_url'] as String?,
      earned: json['earned'] as bool? ?? false,
      earnedAt: rawEarnedAt is String ? DateTime.tryParse(rawEarnedAt) : null,
    );
  }
}
