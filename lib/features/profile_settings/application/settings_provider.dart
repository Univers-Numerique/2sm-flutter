import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account_settings.dart';
import '../data/profile_repository.dart';

final accountSettingsProvider = FutureProvider.autoDispose<AccountSettings>((ref) {
  return ref.watch(profileRepositoryProvider).fetchSettings();
});
