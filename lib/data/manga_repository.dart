import '../models/manga.dart';
import '../source_extensions/source_loader.dart';

class MangaRepository {
  final SourceLoader loader;

  MangaRepository({required this.loader});

  Future<List<Manga>> fetchMangaList({
    String? query,
    String? category,
    MangaSourceType sourceType = MangaSourceType.jikan,
  }) async {
    return await loader.fetchFromSource(
      query: query,
      category: category,
      sourceType: sourceType,
    );
  }
}
