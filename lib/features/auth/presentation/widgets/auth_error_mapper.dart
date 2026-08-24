import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';

@immutable
class AuthErrorPresentation {
  const AuthErrorPresentation({required this.fieldErrors, this.message});

  final Map<String, String> fieldErrors;
  final String? message;
}

AuthErrorPresentation presentAuthError(
  Object error, {
  required Set<String> knownFields,
}) {
  if (error is! ApiException) {
    return const AuthErrorPresentation(
      fieldErrors: {},
      message: 'Terjadi kesalahan tak terduga. Coba lagi sebentar.',
    );
  }

  final inline = <String, String>{};
  final leftovers = <String>[];

  error.fieldErrors.forEach((field, messages) {
    if (messages.isEmpty) return;
    if (knownFields.contains(field)) {
      inline[field] = messages.first;
    } else {
      leftovers.addAll(messages);
    }
  });

  if (inline.isEmpty) {
    return AuthErrorPresentation(
      fieldErrors: const {},
      message: leftovers.isEmpty ? error.message : leftovers.join('\n'),
    );
  }

  return AuthErrorPresentation(
    fieldErrors: inline,
    message: leftovers.isEmpty ? null : leftovers.join('\n'),
  );
}
