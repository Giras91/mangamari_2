import '../models/manga.dart';

class MangaDetailsViewModel {
  final Manga manga;
  MangaDetailsViewModel(this.manga);

  List<Chapter> get chapters => manga.chapters;
}
