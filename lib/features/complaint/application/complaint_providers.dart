import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/complaint_repository.dart';
import '../data/models/complaint_agency.dart';

final complaintAgenciesProvider =
    FutureProvider.autoDispose<List<ComplaintAgency>>((ref) {
      return ref.watch(complaintRepositoryProvider).agencies();
    });

final complaintCategoriesProvider =
    FutureProvider.autoDispose<List<ComplaintCategory>>((ref) {
      return ref.watch(complaintRepositoryProvider).categories();
    });

final complaintAgencyDetailProvider = FutureProvider.autoDispose
    .family<ComplaintAgencyDetail, String>((ref, slug) {
      return ref.watch(complaintRepositoryProvider).agencyDetail(slug);
    });

/// Pembuka URL eksternal (https, wa.me, tel:, mailto:). Dipisah sebagai
/// provider supaya bisa di-override pada test tanpa memanggil platform channel.
final externalUrlLauncherProvider = Provider<Future<bool> Function(Uri uri)>((
  ref,
) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});
