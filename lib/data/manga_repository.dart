import '../models/manga.dart';
import '../source_extensions/source_loader.dart';

class MangaRepository {
  final SourceLoader loader;

  MangaRepository({required this.loader});

  Future<List<Manga>> fetchMangaList({String? query, String? category}) async {
    // Use the real loader integration
    return await loader.fetchFromOpenSource(query: query, category: category);
  }
}
