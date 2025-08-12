import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../models/source_definition.dart';
/// JSON-configured source that uses CSS selectors to parse manga sites
/// This allows adding new sources without writing Dart code
class JSONConfiguredSource extends SourceDefinition {
  final JSONSourceConfig config;
  // Removed stray single quote for error cleanup
  JSONConfiguredSource(this.config) : super(
    id: config.id,
    name: config.name,
    version: config.version,
    baseUrl: config.baseUrl,
    type: SourceType.jsonConfigured,
    isNsfw: config.isNsfw,
    language: config.language,
    supportedFeatures: config.supportedFeatures,
  );

  @override
  Future<List<MangaResult>> getPopularManga({int page = 1}) async {
    if (config.popularPage == null) {
      throw UnsupportedError('Popular manga not supported by this source');
    }
    
    final url = _buildUrl(config.popularPage!.url, page);
    return _parseMangaList(url, config.popularPage!.selectors);
  }

  @override
  Future<List<MangaResult>> getLatestManga({int page = 1}) async {
    if (config.latestPage == null) {
      throw UnsupportedError('Latest manga not supported by this source');
    }
    
    final url = _buildUrl(config.latestPage!.url, page);
    return _parseMangaList(url, config.latestPage!.selectors);
  }

  @override
  Future<List<MangaResult>> searchManga(String query, {int page = 1}) async {
    if (config.searchPage == null) {
      throw UnsupportedError('Search not supported by this source');
    }
    
    final url = _buildSearchUrl(config.searchPage!.url, query, page);
    return _parseMangaList(url, config.searchPage!.selectors);
  }

  @override
  Future<MangaDetails> getMangaDetails(String mangaUrl) async {
    final response = await http.get(Uri.parse(mangaUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch manga details: ${response.statusCode}');
    }

    final document = html.parse(response.body);
    final selectors = config.detailsPage.selectors;

    final title = _extractText(document, selectors.title);
    final description = _extractText(document, selectors.description) ?? '';
    final coverImageUrl = _extractAttribute(document, selectors.coverImage, 'src');
    final status = _extractText(document, selectors.status);
    final author = _extractText(document, selectors.author);
    final genres = _extractMultipleTexts(document, selectors.genres);

    // Extract chapters
    final chapterElements = document.querySelectorAll(selectors.chapterList);
    final chapters = chapterElements.map((element) {
      final chapterTitle = _extractText(element, selectors.chapterTitle) ?? '';
      final chapterUrl = _makeAbsoluteUrl(_extractAttribute(element, selectors.chapterUrl, 'href') ?? '');
      final chapterNumber = _extractText(element, selectors.chapterNumber);
      
      return ChapterInfo(
        title: chapterTitle,
        url: chapterUrl,
        number: chapterNumber,
      );
    }).toList();

    return MangaDetails(
      title: title ?? 'Unknown',
      url: mangaUrl,
      coverImageUrl: coverImageUrl != null ? _makeAbsoluteUrl(coverImageUrl) : null,
      description: description,
      genres: genres,
      status: status,
      author: author,
      chapters: chapters,
    );
  }

  @override
  Future<List<String>> getChapterPages(String chapterUrl) async {
    final response = await http.get(Uri.parse(chapterUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch chapter pages: ${response.statusCode}');
    }

    final document = html.parse(response.body);
    final pageElements = document.querySelectorAll(config.readerPage.selectors.pageImages);
    
    return pageElements
        .map((element) => _extractAttribute(element, null, 'src') ?? 
                          _extractAttribute(element, null, 'data-src'))
        .where((url) => url != null)
        .map((url) => _makeAbsoluteUrl(url!))
        .toList();
  }

  @override
  bool validate() {
    try {
      return config.id.isNotEmpty &&
             config.name.isNotEmpty &&
             config.baseUrl.isNotEmpty &&
             Uri.parse(config.baseUrl).isAbsolute;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  String _buildUrl(String template, int page) {
    return template
        .replaceAll('{baseUrl}', baseUrl)
        .replaceAll('{page}', page.toString());
  }

  String _buildSearchUrl(String template, String query, int page) {
    return template
        .replaceAll('{baseUrl}', baseUrl)
        .replaceAll('{query}', Uri.encodeComponent(query))
        .replaceAll('{page}', page.toString());
  }

  Future<List<MangaResult>> _parseMangaList(String url, MangaListSelectors selectors) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch manga list: ${response.statusCode}');
    }

    final document = html.parse(response.body);
    final mangaElements = document.querySelectorAll(selectors.mangaItem);

    return mangaElements.map((element) {
      final title = _extractText(element, selectors.title);
      final url = _makeAbsoluteUrl(_extractAttribute(element, selectors.url, 'href') ?? '');
      final coverImageUrl = _extractAttribute(element, selectors.coverImage, 'src');
      final description = _extractText(element, selectors.description);
      final genres = _extractMultipleTexts(element, selectors.genres);

      return MangaResult(
        title: title ?? 'Unknown',
        url: url,
        coverImageUrl: coverImageUrl != null ? _makeAbsoluteUrl(coverImageUrl) : null,
        description: description,
        genres: genres,
      );
    }).toList();
  }

  String? _extractText(dynamic document, String? selector) {
    if (selector == null || selector.isEmpty) return null;
    final element = document.querySelector(selector);
    return element?.text.trim();
  }

  String? _extractAttribute(dynamic document, String? selector, String attribute) {
    if (selector == null || selector.isEmpty) {
      return document.attributes?[attribute];
    }
    final element = document.querySelector(selector);
    return element?.attributes[attribute];
  }

  List<String> _extractMultipleTexts(dynamic document, String? selector) {
    if (selector == null || selector.isEmpty) return [];
    final elements = document.querySelectorAll(selector);
    return elements.map((e) => e.text.trim()).where((text) => text.isNotEmpty).toList();
  }

  String _makeAbsoluteUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }
}

/// Configuration class for JSON-based source definitions
class JSONSourceConfig {
  final String id;
  final String name;
  final String version;
  final String baseUrl;
  final bool isNsfw;
  final String language;
  final List<String> supportedFeatures;
  final PageConfig? popularPage;
  final PageConfig? latestPage;
  final PageConfig? searchPage;
  final DetailsPageConfig detailsPage;
  final ReaderPageConfig readerPage;

  const JSONSourceConfig({
    required this.id,
    required this.name,
    required this.version,
    required this.baseUrl,
    this.isNsfw = false,
    this.language = 'en',
    this.supportedFeatures = const [],
    this.popularPage,
    this.latestPage,
    this.searchPage,
    required this.detailsPage,
    required this.readerPage,
  });

  factory JSONSourceConfig.fromJson(Map<String, dynamic> json) {
    return JSONSourceConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      baseUrl: json['baseUrl'] as String,
      isNsfw: json['isNsfw'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      supportedFeatures: (json['supportedFeatures'] as List<dynamic>?)?.cast<String>() ?? [],
      popularPage: json['popularPage'] != null ? PageConfig.fromJson(json['popularPage']) : null,
      latestPage: json['latestPage'] != null ? PageConfig.fromJson(json['latestPage']) : null,
      searchPage: json['searchPage'] != null ? PageConfig.fromJson(json['searchPage']) : null,
      detailsPage: DetailsPageConfig.fromJson(json['detailsPage']),
      readerPage: ReaderPageConfig.fromJson(json['readerPage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'baseUrl': baseUrl,
      'isNsfw': isNsfw,
      'language': language,
      'supportedFeatures': supportedFeatures,
      'popularPage': popularPage?.toJson(),
      'latestPage': latestPage?.toJson(),
      'searchPage': searchPage?.toJson(),
      'detailsPage': detailsPage.toJson(),
      'readerPage': readerPage.toJson(),
    };
  }
}

class PageConfig {
  final String url;
  final MangaListSelectors selectors;

  const PageConfig({
    required this.url,
    required this.selectors,
  });

  factory PageConfig.fromJson(Map<String, dynamic> json) {
    return PageConfig(
      url: json['url'] as String,
      selectors: MangaListSelectors.fromJson(json['selectors']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'selectors': selectors.toJson(),
    };
  }
}

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
      'title': title,
      'url': url,
      'coverImage': coverImage,
      'description': description,
      'genres': genres,
    };
  }
}

class DetailsPageConfig {
  final MangaDetailsSelectors selectors;

  const DetailsPageConfig({
    required this.selectors,
  });

  factory DetailsPageConfig.fromJson(Map<String, dynamic> json) {
    return DetailsPageConfig(
      selectors: MangaDetailsSelectors.fromJson(json['selectors']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectors': selectors.toJson(),
    };
  }
}

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
      'title': title,
      'description': description,
      'coverImage': coverImage,
      'status': status,
      'author': author,
      'genres': genres,
      'chapterList': chapterList,
      'chapterTitle': chapterTitle,
      'chapterUrl': chapterUrl,
      'chapterNumber': chapterNumber,
    };
  }
}

class ReaderPageConfig {
  final ReaderSelectors selectors;

  const ReaderPageConfig({
    required this.selectors,
  });

  factory ReaderPageConfig.fromJson(Map<String, dynamic> json) {
    return ReaderPageConfig(
      selectors: ReaderSelectors.fromJson(json['selectors']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectors': selectors.toJson(),
    };
  }
}

class ReaderSelectors {
  final String pageImages;

  const ReaderSelectors({
    required this.pageImages,
  });

  factory ReaderSelectors.fromJson(Map<String, dynamic> json) {
    return ReaderSelectors(
      pageImages: json['pageImages'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageImages': pageImages,
    };
  }
}
