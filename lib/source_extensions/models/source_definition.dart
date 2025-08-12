/// Abstract base class for all manga source definitions
/// This provides a common interface for different source types
abstract class SourceDefinition {
  final String id;
  final String name;
  final String version;
  final String baseUrl;
  final SourceType type;
  final bool isNsfw;
  final String language;
  final List<String> supportedFeatures;
  
  const SourceDefinition({
    required this.id,
    required this.name,
    required this.version,
    required this.baseUrl,
    required this.type,
    this.isNsfw = false,
    this.language = 'en',
    this.supportedFeatures = const [],
  });

  /// Fetch popular manga list
  Future<List<MangaResult>> getPopularManga({int page = 1});
  
  /// Fetch latest manga list
  Future<List<MangaResult>> getLatestManga({int page = 1});
  
  /// Search manga by query
  Future<List<MangaResult>> searchManga(String query, {int page = 1});
  
  /// Get manga details and chapters
  Future<MangaDetails> getMangaDetails(String mangaUrl);
  
  /// Get chapter page URLs
  Future<List<String>> getChapterPages(String chapterUrl);
  
  /// Validate source configuration
  bool validate();
}

/// Types of manga sources supported
enum SourceType {
  htmlScraping,
  jsonConfigured,
  externalExtension,
}

/// Result from manga list operations
class MangaResult {
  final String title;
  final String url;
  final String? coverImageUrl;
  final String? description;
  final List<String> genres;
  final String? status;
  final String? author;
  final double? rating;

  const MangaResult({
    required this.title,
    required this.url,
    this.coverImageUrl,
    this.description,
    this.genres = const [],
    this.status,
    this.author,
    this.rating,
  });

  factory MangaResult.fromJson(Map<String, dynamic> json) {
    return MangaResult(
      title: json['title'] as String,
      url: json['url'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      description: json['description'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] as String?,
      author: json['author'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'genres': genres,
      'status': status,
      'author': author,
      'rating': rating,
    };
  }
}

/// Detailed manga information with chapters
class MangaDetails {
  final String title;
  final String url;
  final String? coverImageUrl;
  final String description;
  final List<String> genres;
  final String? status;
  final String? author;
  final double? rating;
  final List<ChapterInfo> chapters;

  const MangaDetails({
    required this.title,
    required this.url,
    this.coverImageUrl,
    required this.description,
    this.genres = const [],
    this.status,
    this.author,
    this.rating,
    this.chapters = const [],
  });

  factory MangaDetails.fromJson(Map<String, dynamic> json) {
    return MangaDetails(
      title: json['title'] as String,
      url: json['url'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      description: json['description'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] as String?,
      author: json['author'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((e) => ChapterInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'genres': genres,
      'status': status,
      'author': author,
      'rating': rating,
      'chapters': chapters.map((e) => e.toJson()).toList(),
    };
  }
}

/// Chapter information
class ChapterInfo {
  final String title;
  final String url;
  final String? number;
  final DateTime? uploadDate;
  final String? scanlator;

  const ChapterInfo({
    required this.title,
    required this.url,
    this.number,
    this.uploadDate,
    this.scanlator,
  });

  factory ChapterInfo.fromJson(Map<String, dynamic> json) {
    return ChapterInfo(
      title: json['title'] as String,
      url: json['url'] as String,
      number: json['number'] as String?,
      uploadDate: json['uploadDate'] != null 
          ? DateTime.parse(json['uploadDate'] as String)
          : null,
      scanlator: json['scanlator'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'number': number,
      'uploadDate': uploadDate?.toIso8601String(),
      'scanlator': scanlator,
    };
  }
}

/// Source metadata for storage and management
class SourceMetadata {
  final String id;
  final String name;
  final String version;
  final SourceType type;
  final String downloadUrl;
  final bool isEnabled;
  final bool isOfficial;
  final DateTime installedAt;
  final DateTime? lastUpdated;
  final String? description;
  final List<String> tags;

  const SourceMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.type,
    required this.downloadUrl,
    this.isEnabled = true,
    this.isOfficial = false,
    required this.installedAt,
    this.lastUpdated,
    this.description,
    this.tags = const [],
  });

  factory SourceMetadata.fromJson(Map<String, dynamic> json) {
    return SourceMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      type: SourceType.values.byName(json['type'] as String),
      downloadUrl: json['downloadUrl'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isOfficial: json['isOfficial'] as bool? ?? false,
      installedAt: DateTime.parse(json['installedAt'] as String),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'type': type.name,
      'downloadUrl': downloadUrl,
      'isEnabled': isEnabled,
      'isOfficial': isOfficial,
      'installedAt': installedAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'description': description,
      'tags': tags,
    };
  }
}
