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

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      title: json['title'] as String? ?? 'Unknown Title',
      coverUrl: json['coverUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((ch) => Chapter.fromJson(ch as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'coverUrl': coverUrl,
      'description': description,
      'chapters': chapters.map((ch) => ch.toJson()).toList(),
    };
  }
}

class Chapter {
  final String title;
  final int number;
  
  Chapter({required this.title, required this.number});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'] as String? ?? '',
      number: json['number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'number': number,
    };
  }
}
