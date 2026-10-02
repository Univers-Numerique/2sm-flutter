import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fields_repository.dart';
import '../data/models/field.dart';

final fieldsListProvider = StreamProvider.autoDispose<List<Field>>((ref) {
  return ref.watch(fieldsRepositoryProvider).watchAll();
});

final fieldDetailProvider = FutureProvider.autoDispose.family<Field, int>((ref, id) {
  return ref.watch(fieldsRepositoryProvider).fetchDetail(id);
});

/// Keyed by (lat, lng, radiusKm).
final nearbyFieldsProvider =
    FutureProvider.autoDispose.family<List<Field>, ({double lat, double lng, double radiusKm})>((ref, args) {
  return ref.watch(fieldsRepositoryProvider).nearby(lat: args.lat, lng: args.lng, radiusKm: args.radiusKm);
});
