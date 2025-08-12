class Manga {
  final String title;
  final String coverUrl;
  final String description;
  final List<Chapter> chapters;

  Manga({
    required this.title,
    required this.coverUrl,
    this.description = '',
    this.chapters = const [],
  });
}

class Chapter {
  final String title;
  final int number;
  Chapter({required this.title, required this.number});
}
