
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../data/manga_repository.dart';
import '../source_extensions/source_loader.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart' show StateProvider;

final cacheDurationProvider = StateProvider<int>((ref) => 5);

final customEndpointProvider = StateProvider<String>((ref) => '');

final downloadsProvider = StateNotifierProvider<DownloadsNotifier, Set<String>>((ref) => DownloadsNotifier());
final historyProvider = StateNotifierProvider<HistoryNotifier, List<String>>((ref) => HistoryNotifier());

class DownloadsNotifier extends StateNotifier<Set<String>> {
  DownloadsNotifier() : super({});
  void add(String chapterId) {
    state = {...state, chapterId};
  }
}

class HistoryNotifier extends StateNotifier<List<String>> {
  HistoryNotifier() : super([]);
  void add(String chapterId) {
    state = [chapterId, ...state.where((id) => id != chapterId)];
    if (state.length > 50) {
      state = state.sublist(0, 50);
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) => FavoritesNotifier());
final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Set<String>>((ref) => BookmarksNotifier());

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});
  void toggle(String mangaTitle) {
    if (state.contains(mangaTitle)) {
      state = {...state}..remove(mangaTitle);
    } else {
      state = {...state, mangaTitle};
    }
  }
}

class BookmarksNotifier extends StateNotifier<Set<String>> {
  BookmarksNotifier() : super({});
  void toggle(String chapterId) {
    if (state.contains(chapterId)) {
      state = {...state}..remove(chapterId);
    } else {
      state = {...state, chapterId};
    }
  }
}
// ...existing code...
// ...existing code...
// ...existing code...

enum MangaCategory { latest, popular, trending }

final sourceLoaderProvider = Provider<SourceLoader>((ref) => SourceLoader());
final mangaRepositoryProvider = Provider<MangaRepository>((ref) => MangaRepository(loader: ref.read(sourceLoaderProvider)));

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<MangaCategory>((ref) => MangaCategory.latest);

final mangaSourceTypeProvider = StateProvider<MangaSourceType>((ref) => MangaSourceType.jikan);

final mangaListProvider = FutureProvider.autoDispose<List<Manga>>((ref) async {
  final repo = ref.read(mangaRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final sourceType = ref.watch(mangaSourceTypeProvider);
  return await repo.fetchMangaList(
    query: query,
    category: category.name,
    sourceType: sourceType,
  );
});
