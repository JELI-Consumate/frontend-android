import 'package:flutter/foundation.dart';

enum ComplaintChannelType {
  website,
  whatsapp,
  phone,
  email,
  app,
  address;

  static ComplaintChannelType parse(Object? raw) {
    return ComplaintChannelType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => ComplaintChannelType.website,
    );
  }

  /// Label tombol bawaan bila backend tidak mengirim `button_label`.
  String get defaultButtonLabel => switch (this) {
    ComplaintChannelType.website => 'Buka Tautan',
    ComplaintChannelType.whatsapp => 'Hubungi via WhatsApp',
    ComplaintChannelType.phone => 'Telepon Sekarang',
    ComplaintChannelType.email => 'Kirim Email',
    ComplaintChannelType.app => 'Buka Aplikasi',
    ComplaintChannelType.address => '',
  };
}

String? _optionalString(Object? raw) {
  return raw is String && raw.trim().isNotEmpty ? raw : null;
}

@immutable
class ComplaintAgency {
  const ComplaintAgency({
    required this.id,
    required this.slug,
    required this.shortName,
    required this.fullName,
    required this.summary,
    required this.logoUrl,
    required this.order,
  });

  final String id;
  final String slug;
  final String shortName;
  final String fullName;
  final String summary;
  final String? logoUrl;
  final int order;

  factory ComplaintAgency.fromJson(Map<String, dynamic> json) {
    return ComplaintAgency(
      id: '${json['id']}',
      slug: json['slug'] as String,
      shortName: json['short_name'] as String,
      fullName: json['full_name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      logoUrl: _optionalString(json['logo_url']),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class ComplaintChannel {
  const ComplaintChannel({
    required this.type,
    required this.label,
    required this.value,
    required this.url,
    required this.buttonLabel,
  });

  final ComplaintChannelType type;
  final String label;
  final String value;

  /// URL siap-buka (https, tel:, mailto:, wa.me). null = kanal hanya informasi.
  final String? url;
  final String? buttonLabel;

  String get actionLabel => buttonLabel ?? type.defaultButtonLabel;

  factory ComplaintChannel.fromJson(Map<String, dynamic> json) {
    return ComplaintChannel(
      type: ComplaintChannelType.parse(json['type']),
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      url: _optionalString(json['url']),
      buttonLabel: _optionalString(json['button_label']),
    );
  }
}

@immutable
class ComplaintAgencyDetail extends ComplaintAgency {
  const ComplaintAgencyDetail({
    required super.id,
    required super.slug,
    required super.shortName,
    required super.fullName,
    required super.summary,
    required super.logoUrl,
    required super.order,
    required this.description,
    required this.whenToContact,
    required this.howToAccess,
    required this.notes,
    required this.channels,
  });

  final String description;
  final List<String> whenToContact;
  final String? howToAccess;
  final String? notes;
  final List<ComplaintChannel> channels;

  factory ComplaintAgencyDetail.fromJson(Map<String, dynamic> json) {
    final base = ComplaintAgency.fromJson(json);
    final when = json['when_to_contact'];
    final channels = json['channels'];

    return ComplaintAgencyDetail(
      id: base.id,
      slug: base.slug,
      shortName: base.shortName,
      fullName: base.fullName,
      summary: base.summary,
      logoUrl: base.logoUrl,
      order: base.order,
      description: json['description'] as String? ?? '',
      whenToContact: when is List
          ? when.whereType<String>().toList()
          : const [],
      howToAccess: _optionalString(json['how_to_access']),
      notes: _optionalString(json['notes']),
      channels: channels is List
          ? channels
                .cast<Map<String, dynamic>>()
                .map(ComplaintChannel.fromJson)
                .toList()
          : const [],
    );
  }
}

@immutable
class ComplaintCategoryAgency {
  const ComplaintCategoryAgency({required this.slug, required this.shortName});

  final String slug;
  final String shortName;
}

@immutable
class ComplaintCategory {
  const ComplaintCategory({
    required this.id,
    required this.problem,
    required this.agencies,
  });

  final String id;
  final String problem;
  final List<ComplaintCategoryAgency> agencies;

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) {
    final agencies = json['agencies'];

    return ComplaintCategory(
      id: '${json['id']}',
      problem: json['problem'] as String,
      agencies: agencies is List
          ? agencies
                .cast<Map<String, dynamic>>()
                .map(
                  (a) => ComplaintCategoryAgency(
                    slug: a['slug'] as String,
                    shortName: a['short_name'] as String,
                  ),
                )
                .toList()
          : const [],
    );
  }
}
