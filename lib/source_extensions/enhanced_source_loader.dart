import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/manga.dart';
import 'models/source_definition.dart';
import 'sources/html_scraping_source.dart';
import 'manager/source_manager.dart';

/// Enhanced source loader that works with the new extension system
/// Maintains backwards compatibility while adding new extension support
class EnhancedSourceLoader {
  static const String _cacheBoxName = 'manga_cache';
  
  Box<String>? _cacheBox;
  
  final SourceManager _sourceManager = SourceManager();
  
  /// Initialize the source loader and extension system
  Future<void> initialize() async {
    await _sourceManager.initialize();
    try {
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    } catch (e) {
      // Cache initialization failed, continue without cache
    }
    
    // Install demo sources for testing
    await _installDemoSources();
  }

  /// Install demo sources for testing purposes
  Future<void> _installDemoSources() async {
    try {
      // Install the public domain demo source
      final demoSource = PublicDomainMangaSource();
      final metadata = SourceMetadata(
        id: demoSource.id,
        name: demoSource.name,
        version: demoSource.version,
        type: demoSource.type,
        downloadUrl: '',
        installedAt: DateTime.now(),
        description: 'Demo source with public domain manga',
        isOfficial: true,
      );
      
      // Add to source manager (simplified installation)
      _sourceManager.installedSources.add(demoSource);
      _sourceManager.sourceMetadata.add(metadata);
    } catch (e) {
      // Demo source installation failed, continue
    }
  }

  /// Get cache information
  Future<Map<String, dynamic>> getCacheInfo() async {
    await _initializeCacheIfNeeded();
    if (_cacheBox == null) {
      return {'count': 0, 'oldest': null, 'newest': null};
    }

    final keys = _cacheBox!.keys;
    if (keys.isEmpty) {
      return {'count': 0, 'oldest': null, 'newest': null};
    }

    return {
      'count': keys.length,
      'oldest': 'N/A',
      'newest': 'N/A',
    };
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _initializeCacheIfNeeded();
    await _cacheBox?.clear();
  }

  /// Refresh cache for specific parameters
  Future<void> refreshCache({
    required String query,
    required String category,
    required MangaSourceType sourceType,
    String? customEndpoint,
  }) async {
    await _initializeCacheIfNeeded();
    
    // Clear relevant cache entries
    final cacheKey = _generateCacheKey(query, category, sourceType.name, customEndpoint);
    await _cacheBox?.delete(cacheKey);
    
    // Fetch fresh data
    await fetchFromSource(
      query: query,
      category: category,
      sourceType: sourceType,
      customEndpoint: customEndpoint,
    );
  }

  /// Main method to fetch manga from sources (backwards compatible)
  Future<List<Manga>> fetchFromSource({
    required String query,
    required String category,
    required MangaSourceType sourceType,
    String? customEndpoint,
  }) async {
    try {
      await _initializeCacheIfNeeded();
      
      // Check cache first
      final cacheKey = _generateCacheKey(query, category, sourceType.name, customEndpoint);
      final cachedData = _getCachedData(cacheKey);
      if (cachedData != null) {
        final List<dynamic> mangaList = jsonDecode(cachedData);
        return mangaList.map((json) => Manga.fromJson(json)).toList();
      }

      List<Manga> results;

      // Use new extension system if available
      if (sourceType == MangaSourceType.extension) {
        results = await _fetchFromExtensions(query, category);
      } else {
        // Fall back to legacy sources
        results = await _fetchFromLegacySource(query, category, sourceType, customEndpoint);
      }

      // Cache the results
      await _cacheData(cacheKey, jsonEncode(results.map((m) => m.toJson()).toList()));
      
      return results;
    } catch (e) {
      throw Exception('Failed to fetch manga: $e');
    }
  }

  /// Fetch from new extension system
  Future<List<Manga>> _fetchFromExtensions(String query, String category) async {
    final enabledSources = _sourceManager.enabledSources;
    final allResults = <Manga>[];

    for (final source in enabledSources) {
      try {
        List<MangaResult> sourceResults;
        
        if (query.isNotEmpty) {
          sourceResults = await source.searchManga(query);
        } else if (category == 'popular') {
          sourceResults = await source.getPopularManga();
        } else {
          sourceResults = await source.getLatestManga();
        }

        // Convert MangaResult to Manga (backwards compatibility)
        final mangaList = sourceResults.map((result) => Manga(
          title: result.title,
          coverUrl: result.coverImageUrl ?? '',
          description: _buildDescription(result),
          chapters: [], // Chapters loaded separately when needed
        )).toList();

        allResults.addAll(mangaList);
      } catch (e) {
        // Continue with other sources if one fails
        continue;
      }
    }

    return allResults;
  }

  /// Legacy source fetching (backwards compatible)
  Future<List<Manga>> _fetchFromLegacySource(
    String query,
    String category,
    MangaSourceType sourceType,
    String? customEndpoint,
  ) async {
    switch (sourceType) {
      case MangaSourceType.jikan:
        return _fetchFromJikan(query, category);
      case MangaSourceType.mangadex:
        return _fetchFromMangadex(query, category);
      case MangaSourceType.comick:
        return _fetchFromComick(query, category);
      case MangaSourceType.custom:
        if (customEndpoint != null && customEndpoint.isNotEmpty) {
          return _fetchFromCustom(customEndpoint, query, category);
        }
        throw Exception('Custom endpoint URL is required');
      case MangaSourceType.extension:
        return _fetchFromExtensions(query, category);
    }
  }

  /// Get installed sources for UI
  List<SourceDefinition> getInstalledSources() {
    return _sourceManager.installedSources;
  }

  /// Get source manager for UI
  SourceManager getSourceManager() {
    return _sourceManager;
  }

  // Legacy source implementations (unchanged for backwards compatibility)
  Future<List<Manga>> _fetchFromJikan(String query, String category) async {
    String url;
    if (query.isNotEmpty) {
      url = 'https://api.jikan.moe/v4/manga?q=${Uri.encodeComponent(query)}&limit=20';
    } else {
      url = 'https://api.jikan.moe/v4/top/manga?limit=20';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> mangaList = data['data'];
      return mangaList.map((json) => _parseJikanManga(json)).toList();
    } else {
      throw Exception('Failed to fetch from Jikan API');
    }
  }

  Future<List<Manga>> _fetchFromMangadex(String query, String category) async {
    String url;
    if (query.isNotEmpty) {
      url = 'https://api.mangadex.org/manga?title=${Uri.encodeComponent(query)}&limit=20&contentRating[]=safe&contentRating[]=suggestive';
    } else {
      url = 'https://api.mangadex.org/manga?limit=20&contentRating[]=safe&contentRating[]=suggestive&order[createdAt]=desc';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> mangaList = data['data'];
      return mangaList.map((json) => _parseMangadexManga(json)).toList();
    } else {
      throw Exception('Failed to fetch from MangaDex API');
    }
  }

  Future<List<Manga>> _fetchFromComick(String query, String category) async {
    String url;
    if (query.isNotEmpty) {
      url = 'https://api.comick.fun/v1.0/search?q=${Uri.encodeComponent(query)}&limit=20';
    } else {
      url = 'https://api.comick.fun/v1.0/comic?limit=20&order=created_at&accept_erotic_content=false';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> mangaList = jsonDecode(response.body);
      return mangaList.map((json) => _parseComickManga(json)).toList();
    } else {
      throw Exception('Failed to fetch from Comick API');
    }
  }

  Future<List<Manga>> _fetchFromCustom(String endpoint, String query, String category) async {
    final uri = Uri.parse(endpoint);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((json) => Manga.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('data')) {
        final List<dynamic> mangaList = data['data'];
        return mangaList.map((json) => Manga.fromJson(json)).toList();
      }
      throw Exception('Invalid response format from custom endpoint');
    } else {
      throw Exception('Failed to fetch from custom endpoint: ${response.statusCode}');
    }
  }

  // Helper methods
  String _buildDescription(MangaResult result) {
    final parts = <String>[];
    
    if (result.description != null && result.description!.isNotEmpty) {
      parts.add(result.description!);
    }
    
    if (result.author != null) {
      parts.add('Author: ${result.author}');
    }
    
    if (result.genres.isNotEmpty) {
      parts.add('Genres: ${result.genres.join(', ')}');
    }
    
    if (result.status != null) {
      parts.add('Status: ${result.status}');
    }

    return parts.join('\n');
  }

  Future<void> _initializeCacheIfNeeded() async {
    if (_cacheBox == null) {
      try {
        _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      } catch (e) {
        // Continue without cache if initialization fails
      }
    }
  }

  String _generateCacheKey(String query, String category, String sourceType, String? customEndpoint) {
    return 'manga_${sourceType}_${category}_${query}_${customEndpoint ?? ''}'.replaceAll(' ', '_');
  }

  String? _getCachedData(String key) {
    if (_cacheBox == null) return null;
    
    try {
      final data = _cacheBox!.get(key);
      if (data != null) {
        // In a real implementation, check timestamp here
        return data;
      }
    } catch (e) {
      // Cache read failed
    }
    
    return null;
  }

  Future<void> _cacheData(String key, String data) async {
    if (_cacheBox == null) return;
    
    try {
      await _cacheBox!.put(key, data);
    } catch (e) {
      // Cache write failed, continue without caching
    }
  }

  // Legacy parsing methods (unchanged)
  Manga _parseJikanManga(Map<String, dynamic> json) {
    return Manga(
      title: json['title'] as String,
      coverUrl: json['images']?['jpg']?['image_url'] as String? ?? '',
      description: json['synopsis'] as String? ?? 'No description available',
      chapters: [],
    );
  }

  Manga _parseMangadexManga(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>;
    final title = attributes['title'] as Map<String, dynamic>;
    final titleText = title['en'] as String? ?? title.values.first as String;
    
    return Manga(
      title: titleText,
      coverUrl: '', // MangaDex covers require additional API call
      description: attributes['description']?['en'] as String? ?? 'No description available',
      chapters: [],
    );
  }

  Manga _parseComickManga(Map<String, dynamic> json) {
    final parts = <String>[];
    
    if (json['desc'] != null && json['desc'].toString().isNotEmpty) {
      parts.add(json['desc'].toString());
    }
    
    if (json['author'] != null) {
      parts.add('Author: ${json['author']}');
    }
    
    if (json['genre'] != null && json['genre'] is List) {
      final genres = (json['genre'] as List).join(', ');
      if (genres.isNotEmpty) {
        parts.add('Genres: $genres');
      }
    }
    
    if (json['status'] != null) {
      parts.add('Status: ${json['status']}');
    }

    return Manga(
      title: json['title'] as String? ?? 'Unknown Title',
      coverUrl: json['cover_url'] as String? ?? '',
      description: parts.join('\n'),
      chapters: [],
    );
  }
}

/// Enhanced enum for backwards compatibility with new extension type
enum MangaSourceType {
  jikan,
  mangadex,
  comick,
  custom,
  extension, // New type for extension system
}
