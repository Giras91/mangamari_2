import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';

enum MangaSourceType { jikan, mangadex, comick, custom }
  /// Fetch manga from a custom open-source endpoint (GET, expects JSON array of manga objects)
  Future<List<Manga>> fetchFromCustomEndpoint(String endpointUrl) async {
    final url = Uri.parse(endpointUrl);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map<Manga>((item) {
          return Manga(
            title: item['title'] ?? 'Unknown',
            coverUrl: item['coverUrl'] ?? '',
            description: item['description'] ?? '',
            chapters: (item['chapters'] as List?)?.map((ch) => Chapter(
              title: ch['title'] ?? '',
              number: ch['number'] ?? 0,
            )).toList() ?? [],
          );
        }).toList();
      } else {
        throw Exception('Custom endpoint did not return a list');
      }
    } else {
      throw Exception('Failed to load manga from custom endpoint');
    }
  }

class _CacheEntry {
  final List<Manga> data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}

class SourceLoader {
  static const String hiveBoxName = 'mangaCacheBox';
  static bool _hiveInitialized = false;
  Box? _box;

  Future<void> _initHive() async {
    if (!_hiveInitialized) {
      await Hive.initFlutter();
      _hiveInitialized = true;
    }
    _box ??= await Hive.openBox(hiveBoxName);
  }
  final Map<String, _CacheEntry> _cache = {};
  Duration cacheDuration = const Duration(minutes: 5);
  /// Set cache duration (in minutes)
  void setCacheDuration(Duration duration) {
    cacheDuration = duration;
  }

  /// Manually refresh cache for a given key (forces API reload)
  Future<List<Manga>> refreshCache({
    String? query,
    String? category,
    MangaSourceType sourceType = MangaSourceType.jikan,
    String? customEndpoint,
  }) async {
    await _initHive();
    final cacheKey = '$sourceType|$query|$category|$customEndpoint';
    if (_box != null) await _box!.delete(cacheKey);
    _cache.remove(cacheKey);
    return await fetchFromSource(
      query: query,
      category: category,
      sourceType: sourceType,
      customEndpoint: customEndpoint,
    );
  }

  /// Get cache info (number of entries, oldest/newest timestamps)
  Future<Map<String, dynamic>> getCacheInfo() async {
    await _initHive();
    final info = <String, dynamic>{};
    info['count'] = _box?.length ?? 0;
    DateTime? oldest;
    DateTime? newest;
    if (_box != null) {
      for (final key in _box!.keys) {
        final entry = _box!.get(key);
        if (entry is Map && entry.containsKey('timestamp')) {
          final ts = DateTime.tryParse(entry['timestamp'] ?? '');
          if (ts != null) {
            if (oldest == null || ts.isBefore(oldest)) oldest = ts;
            if (newest == null || ts.isAfter(newest)) newest = ts;
          }
        }
      }
    }
    info['oldest'] = oldest?.toIso8601String();
    info['newest'] = newest?.toIso8601String();
    return info;
  }

  Future<void> clearCache() async {
    _cache.clear();
    await _initHive();
    await _box?.clear();
  }

  Future<void> _pruneCache() async {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.difference(entry.timestamp) > cacheDuration);
    await _initHive();
    if (_box != null) {
      final keysToRemove = <dynamic>[];
      for (final key in _box!.keys) {
        final entry = _box!.get(key);
        if (entry is Map && entry.containsKey('timestamp')) {
          final ts = DateTime.tryParse(entry['timestamp'] ?? '') ?? now;
          if (now.difference(ts) > cacheDuration) {
            keysToRemove.add(key);
          }
        }
      }
      for (final key in keysToRemove) {
        await _box!.delete(key);
      }
    }
  }
  Future<List<Manga>> fetchFromSource({
    String? query,
    String? category,
    MangaSourceType sourceType = MangaSourceType.jikan,
    String? customEndpoint,
  }) async {
    await _pruneCache();
    await _initHive();
    final cacheKey = '$sourceType|$query|$category|$customEndpoint';
    // In-memory cache
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp) <= cacheDuration) {
        return entry.data;
      } else {
        _cache.remove(cacheKey);
      }
    }
    // Persistent cache
    if (_box != null && _box!.containsKey(cacheKey)) {
      final entry = _box!.get(cacheKey);
      if (entry is Map && entry.containsKey('data') && entry.containsKey('timestamp')) {
        final ts = DateTime.tryParse(entry['timestamp'] ?? '') ?? DateTime.now();
        if (DateTime.now().difference(ts) <= cacheDuration) {
          final List<dynamic> rawList = entry['data'] as List<dynamic>;
          final List<Manga> mangas = rawList.map((item) => Manga(
            title: item['title'] ?? 'Unknown',
            coverUrl: item['coverUrl'] ?? '',
            description: item['description'] ?? '',
            chapters: (item['chapters'] as List?)?.map((ch) => Chapter(
              title: ch['title'] ?? '',
              number: ch['number'] ?? 0,
            )).toList() ?? [],
          )).toList();
          _cache[cacheKey] = _CacheEntry(mangas, ts);
          return mangas;
        } else {
          await _box!.delete(cacheKey);
        }
      }
    }
    switch (sourceType) {
      case MangaSourceType.jikan:
        final url = Uri.parse('https://api.jikan.moe/v4/manga?q=${query ?? ''}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['data'] ?? [];
          final mangas = results.map((item) {
            return Manga(
              title: item['title'] ?? 'Unknown',
              coverUrl: item['images']?['jpg']?['image_url'] ?? '',
              description: item['synopsis'] ?? '',
              chapters: [],
            );
          }).toList();
          _cache[cacheKey] = _CacheEntry(mangas, DateTime.now());
          await _box?.put(cacheKey, {
            'data': mangas.map((m) => {
              'title': m.title,
              'coverUrl': m.coverUrl,
              'description': m.description,
              'chapters': m.chapters.map((c) => {
                'title': c.title,
                'number': c.number,
              }).toList(),
            }).toList(),
            'timestamp': DateTime.now().toIso8601String(),
          });
          return mangas;
        } else {
          throw Exception('Failed to load manga from Jikan');
        }
      case MangaSourceType.mangadex:
        final url = Uri.parse('https://api.mangadex.org/manga?title=${query ?? ''}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['data'] ?? [];
          final mangas = results.map((item) {
            final attributes = item['attributes'] ?? {};
            final titleMap = attributes['title'] ?? {};
            final title = titleMap.values.isNotEmpty ? titleMap.values.first : 'Unknown';
            final coverArt = (item['relationships'] as List?)?.firstWhere(
              (rel) => rel['type'] == 'cover_art',
              orElse: () => null,
            );
            final coverId = coverArt != null ? coverArt['id'] : null;
            final coverUrl = coverId != null
              ? 'https://uploads.mangadex.org/covers/$coverId.jpg'
              : '';
            return Manga(
              title: title,
              coverUrl: coverUrl,
              description: attributes['description'] ?? '',
              chapters: [],
            );
          }).toList();
          _cache[cacheKey] = _CacheEntry(mangas, DateTime.now());
          await _box?.put(cacheKey, {
            'data': mangas.map((m) => {
              'title': m.title,
              'coverUrl': m.coverUrl,
              'description': m.description,
              'chapters': m.chapters.map((c) => {
                'title': c.title,
                'number': c.number,
              }).toList(),
            }).toList(),
            'timestamp': DateTime.now().toIso8601String(),
          });
          return mangas;
        } else {
          throw Exception('Failed to load manga from Mangadex');
        }
      case MangaSourceType.comick:
        // Comick open API integration
        final url = Uri.parse('https://api.comick.io/v1.0/search?type=manga&title=${Uri.encodeComponent(query ?? '')}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['manga'] ?? [];
          final mangas = results.map((item) {
            List<Chapter> chapters = [];
            if (item['chapters'] is List) {
              chapters = (item['chapters'] as List).map((ch) {
                return Chapter(
                  title: ch['title'] ?? 'Chapter',
                  number: ch['chap'] ?? 0,
                );
              }).toList();
            }
            final author = item['author'] ?? '';
            final genres = (item['genres'] as List?)?.map((g) => g.toString()).join(', ') ?? '';
            final status = item['status'] ?? '';
            final description = [item['desc'], if (author.isNotEmpty) 'Author: $author', if (genres.isNotEmpty) 'Genres: $genres', if (status.isNotEmpty) 'Status: $status']
              .where((e) => e != null && e.toString().isNotEmpty)
              .join('\n');
            return Manga(
              title: item['title'] ?? 'Unknown',
              coverUrl: item['md_covers'] != null && item['md_covers'].isNotEmpty
                ? 'https://uploads.comick.io/${item['md_covers'][0]['b2key']}'
                : '',
              description: description,
              chapters: chapters,
            );
          }).toList();
          _cache[cacheKey] = _CacheEntry(mangas, DateTime.now());
          await _box?.put(cacheKey, {
            'data': mangas.map((m) => {
              'title': m.title,
              'coverUrl': m.coverUrl,
              'description': m.description,
              'chapters': m.chapters.map((c) => {
                'title': c.title,
                'number': c.number,
              }).toList(),
            }).toList(),
            'timestamp': DateTime.now().toIso8601String(),
          });
          return mangas;
        } else {
          throw Exception('Failed to load manga from Comick');
        }
      case MangaSourceType.custom:
        if (customEndpoint == null || customEndpoint.isEmpty) {
          throw Exception('Custom endpoint URL required');
        }
  final mangas = await fetchFromCustomEndpoint(customEndpoint);
        _cache[cacheKey] = _CacheEntry(mangas, DateTime.now());
        await _box?.put(cacheKey, {
          'data': mangas.map((m) => {
            'title': m.title,
            'coverUrl': m.coverUrl,
            'description': m.description,
            'chapters': m.chapters.map((c) => {
              'title': c.title,
              'number': c.number,
            }).toList(),
          }).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        });
  return mangas;
    }
  }
}
