import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/news.dart';
import '../data/news_repository.dart';

final newsFeedProvider = StreamProvider.autoDispose<List<News>>((ref) {
  return ref.watch(newsRepositoryProvider).watchAll();
});

final newsDetailProvider = FutureProvider.autoDispose.family<News, int>((ref, id) {
  return ref.watch(newsRepositoryProvider).fetchDetail(id);
});
