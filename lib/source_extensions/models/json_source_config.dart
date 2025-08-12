/// Configuration for JSON-based manga sources
class JSONSourceConfig {
  final String id;
  final String name;
  final String version;
  final String baseUrl;
  final String language;
  final List<String> supportedFeatures;
  final PageConfig? popularPage;
  final PageConfig? latestPage;
  final PageConfig? searchPage;
  final DetailsPageConfig? detailsPage;
  final ReaderPageConfig? readerPage;
  final Map<String, dynamic>? customSettings;

  const JSONSourceConfig({
    required this.id,
    required this.name,
    required this.version,
    required this.baseUrl,
    required this.language,
    this.supportedFeatures = const [],
    this.popularPage,
    this.latestPage,
    this.searchPage,
    this.detailsPage,
    this.readerPage,
    this.customSettings,
  });

  factory JSONSourceConfig.fromJson(Map<String, dynamic> json) {
    return JSONSourceConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      baseUrl: json['baseUrl'] as String,
      language: json['language'] as String,
      supportedFeatures: (json['supportedFeatures'] as List<dynamic>?)
          ?.cast<String>() ?? [],
      popularPage: json['popularPage'] != null
          ? PageConfig.fromJson(json['popularPage'] as Map<String, dynamic>)
          : null,
      latestPage: json['latestPage'] != null
          ? PageConfig.fromJson(json['latestPage'] as Map<String, dynamic>)
          : null,
      searchPage: json['searchPage'] != null
          ? PageConfig.fromJson(json['searchPage'] as Map<String, dynamic>)
          : null,
      detailsPage: json['detailsPage'] != null
          ? DetailsPageConfig.fromJson(json['detailsPage'] as Map<String, dynamic>)
          : null,
      readerPage: json['readerPage'] != null
          ? ReaderPageConfig.fromJson(json['readerPage'] as Map<String, dynamic>)
          : null,
      customSettings: json['customSettings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'baseUrl': baseUrl,
      'language': language,
      'supportedFeatures': supportedFeatures,
      if (popularPage != null) 'popularPage': popularPage!.toJson(),
      if (latestPage != null) 'latestPage': latestPage!.toJson(),
      if (searchPage != null) 'searchPage': searchPage!.toJson(),
      if (detailsPage != null) 'detailsPage': detailsPage!.toJson(),
      if (readerPage != null) 'readerPage': readerPage!.toJson(),
      if (customSettings != null) 'customSettings': customSettings,
    };
  }
}

/// Configuration for manga list pages (popular, latest, search)
class PageConfig {
  final String url;
  final MangaListSelectors selectors;
  final Map<String, String>? headers;
  final String? method;

  const PageConfig({
    required this.url,
    required this.selectors,
    this.headers,
    this.method = 'GET',
  });

  factory PageConfig.fromJson(Map<String, dynamic> json) {
    return PageConfig(
      url: json['url'] as String,
      selectors: MangaListSelectors.fromJson(
        json['selectors'] as Map<String, dynamic>,
      ),
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
      method: json['method'] as String? ?? 'GET',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'selectors': selectors.toJson(),
      if (headers != null) 'headers': headers,
      'method': method,
    };
  }
}

/// Selectors for manga list items
class MangaListSelectors {
  final String mangaItem;
  final String? title;
  final String? url;
  final String? coverImage;
  final String? description;
  final String? genres;

  const MangaListSelectors({
    required this.mangaItem,
    this.title,
    this.url,
    this.coverImage,
    this.description,
    this.genres,
  });

  factory MangaListSelectors.fromJson(Map<String, dynamic> json) {
    return MangaListSelectors(
      mangaItem: json['mangaItem'] as String,
      title: json['title'] as String?,
      url: json['url'] as String?,
      coverImage: json['coverImage'] as String?,
      description: json['description'] as String?,
      genres: json['genres'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mangaItem': mangaItem,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (coverImage != null) 'coverImage': coverImage,
      if (description != null) 'description': description,
      if (genres != null) 'genres': genres,
    };
  }
}

/// Configuration for manga details pages
class DetailsPageConfig {
  final MangaDetailsSelectors selectors;
  final Map<String, String>? headers;

  const DetailsPageConfig({
    required this.selectors,
    this.headers,
  });

  factory DetailsPageConfig.fromJson(Map<String, dynamic> json) {
    return DetailsPageConfig(
      selectors: MangaDetailsSelectors.fromJson(
        json['selectors'] as Map<String, dynamic>,
      ),
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectors': selectors.toJson(),
      if (headers != null) 'headers': headers,
    };
  }
}

/// Selectors for manga details
class MangaDetailsSelectors {
  final String? title;
  final String? description;
  final String? coverImage;
  final String? status;
  final String? author;
  final String? genres;
  final String chapterList;
  final String? chapterTitle;
  final String? chapterUrl;
  final String? chapterNumber;

  const MangaDetailsSelectors({
    this.title,
    this.description,
    this.coverImage,
    this.status,
    this.author,
    this.genres,
    required this.chapterList,
    this.chapterTitle,
    this.chapterUrl,
    this.chapterNumber,
  });

  factory MangaDetailsSelectors.fromJson(Map<String, dynamic> json) {
    return MangaDetailsSelectors(
      title: json['title'] as String?,
      description: json['description'] as String?,
      coverImage: json['coverImage'] as String?,
      status: json['status'] as String?,
      author: json['author'] as String?,
      genres: json['genres'] as String?,
      chapterList: json['chapterList'] as String,
      chapterTitle: json['chapterTitle'] as String?,
      chapterUrl: json['chapterUrl'] as String?,
      chapterNumber: json['chapterNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (coverImage != null) 'coverImage': coverImage,
      if (status != null) 'status': status,
      if (author != null) 'author': author,
      if (genres != null) 'genres': genres,
      'chapterList': chapterList,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
      if (chapterUrl != null) 'chapterUrl': chapterUrl,
      if (chapterNumber != null) 'chapterNumber': chapterNumber,
    };
  }
}

/// Configuration for reader pages
class ReaderPageConfig {
  final ReaderSelectors selectors;
  final Map<String, String>? headers;

  const ReaderPageConfig({
    required this.selectors,
    this.headers,
  });

  factory ReaderPageConfig.fromJson(Map<String, dynamic> json) {
    return ReaderPageConfig(
      selectors: ReaderSelectors.fromJson(
        json['selectors'] as Map<String, dynamic>,
      ),
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectors': selectors.toJson(),
      if (headers != null) 'headers': headers,
    };
  }
}

/// Selectors for reader pages
class ReaderSelectors {
  final String pageImages;
  final String? nextPageUrl;
  final String? prevPageUrl;

  const ReaderSelectors({
    required this.pageImages,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory ReaderSelectors.fromJson(Map<String, dynamic> json) {
    return ReaderSelectors(
      pageImages: json['pageImages'] as String,
      nextPageUrl: json['nextPageUrl'] as String?,
      prevPageUrl: json['prevPageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageImages': pageImages,
      if (nextPageUrl != null) 'nextPageUrl': nextPageUrl,
      if (prevPageUrl != null) 'prevPageUrl': prevPageUrl,
    };
  }
}
