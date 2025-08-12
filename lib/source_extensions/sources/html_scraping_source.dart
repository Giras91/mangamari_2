import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../models/source_definition.dart';

/// HTML scraping source for Project Gutenberg comics/manga
/// This demonstrates direct Dart implementation for complex scraping
class ProjectGutenbergMangaSource extends SourceDefinition {
  ProjectGutenbergMangaSource() : super(
    id: 'project_gutenberg_manga',
    name: 'Project Gutenberg Comics',
    version: '1.0.0',
    baseUrl: 'https://www.gutenberg.org',
    type: SourceType.htmlScraping,
    language: 'en',
    supportedFeatures: ['search'],
  );

  @override
  Future<List<MangaResult>> getPopularManga({int page = 1}) async {
    // Project Gutenberg doesn't have a "popular" concept, so we'll return latest
    return getLatestManga(page: page);
  }

  @override
  Future<List<MangaResult>> getLatestManga({int page = 1}) async {
    // Search for comic-related works
    return searchManga('comic', page: page);
  }

  @override
  Future<List<MangaResult>> searchManga(String query, {int page = 1}) async {
    final searchUrl = '$baseUrl/ebooks/search/?query=${Uri.encodeComponent(query)}+comic&start_index=${(page - 1) * 25}';
    
    final response = await http.get(Uri.parse(searchUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch search results: ${response.statusCode}');
    }

    final document = html.parse(response.body);
    final results = <MangaResult>[];

    // Parse search results
    final bookItems = document.querySelectorAll('.booklink');
    
    for (final item in bookItems) {
      final titleElement = item.querySelector('span.title');
      final linkElement = item.querySelector('a');
      
      if (titleElement != null && linkElement != null) {
        final title = titleElement.text.trim();
        final relativeUrl = linkElement.attributes['href'] ?? '';
        final url = relativeUrl.startsWith('http') ? relativeUrl : '$baseUrl$relativeUrl';
        
        // Look for author information
        final authorElement = item.querySelector('span.subtitle');
        final author = authorElement?.text.trim();

        results.add(MangaResult(
          title: title,
          url: url,
          author: author,
          description: 'Public domain work from Project Gutenberg',
          genres: const ['Classic', 'Public Domain'],
        ));
      }
    }

    return results;
  }

  @override
  Future<MangaDetails> getMangaDetails(String mangaUrl) async {
    final response = await http.get(Uri.parse(mangaUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch manga details: ${response.statusCode}');
    }

    final document = html.parse(response.body);
    
    // Extract basic information
    final titleElement = document.querySelector('h1[itemprop="name"]');
    final title = titleElement?.text.trim() ?? 'Unknown Title';
    
    final authorElement = document.querySelector('a[itemprop="creator"]');
    final author = authorElement?.text.trim();
    
    final descriptionElement = document.querySelector('.description');
    final description = descriptionElement?.text.trim() ?? 'No description available';

    // Look for downloadable formats (chapters)
    final chapters = <ChapterInfo>[];
    final downloadLinks = document.querySelectorAll('.files a[href*=".pdf"], .files a[href*=".epub"]');
    
    for (int i = 0; i < downloadLinks.length; i++) {
      final link = downloadLinks[i];
      final href = link.attributes['href'] ?? '';
      final format = href.contains('.pdf') ? 'PDF' : 'EPUB';
      final chapterUrl = href.startsWith('http') ? href : '$baseUrl$href';
      
      chapters.add(ChapterInfo(
        title: '$format Version',
        url: chapterUrl,
        number: (i + 1).toString(),
      ));
    }

    return MangaDetails(
      title: title,
      url: mangaUrl,
      description: description,
      author: author,
      genres: const ['Classic', 'Public Domain', 'Historical'],
      status: 'Completed',
      chapters: chapters,
    );
  }

  @override
  Future<List<String>> getChapterPages(String chapterUrl) async {
    // For Project Gutenberg, chapters are typically PDF/EPUB files
    // In a real implementation, you might extract images from PDFs
    // For now, we'll return the download URL as a single "page"
    return [chapterUrl];
  }

  @override
  bool validate() {
    return baseUrl.isNotEmpty && baseUrl.startsWith('https://');
  }
}

/// Example of a working public domain manga source
/// This creates a hardcoded source for demonstration
class PublicDomainMangaSource extends SourceDefinition {
  PublicDomainMangaSource() : super(
    id: 'public_domain_demo',
    name: 'Public Domain Demo',
    version: '1.0.0',
    baseUrl: 'https://example.com',
    type: SourceType.htmlScraping,
    language: 'en',
    supportedFeatures: ['popular', 'latest', 'search'],
  );

  @override
  Future<List<MangaResult>> getPopularManga({int page = 1}) async {
    // Return sample public domain manga
    return _getSampleManga();
  }

  @override
  Future<List<MangaResult>> getLatestManga({int page = 1}) async {
    return _getSampleManga();
  }

  @override
  Future<List<MangaResult>> searchManga(String query, {int page = 1}) async {
    final allManga = _getSampleManga();
    return allManga.where((manga) => 
      manga.title.toLowerCase().contains(query.toLowerCase()) ||
      manga.description?.toLowerCase().contains(query.toLowerCase()) == true
    ).toList();
  }

  @override
  Future<MangaDetails> getMangaDetails(String mangaUrl) async {
    // Return detailed information for sample manga
    return MangaDetails(
      title: 'Little Nemo in Slumberland',
      url: mangaUrl,
      description: 'Little Nemo in Slumberland is a famous comic strip by Winsor McCay. Originally published in the early 1900s, this work is now in the public domain and represents some of the finest early comic art.',
      author: 'Winsor McCay',
      genres: const ['Classic', 'Fantasy', 'Public Domain'],
      status: 'Completed',
      chapters: [
        ChapterInfo(
          title: 'Chapter 1: The Land of Wonderful Dreams',
          url: '$baseUrl/chapter/1',
          number: '1',
        ),
        ChapterInfo(
          title: 'Chapter 2: The Palace of Ice',
          url: '$baseUrl/chapter/2',
          number: '2',
        ),
        ChapterInfo(
          title: 'Chapter 3: The Dancing Bed',
          url: '$baseUrl/chapter/3',
          number: '3',
        ),
      ],
    );
  }

  @override
  Future<List<String>> getChapterPages(String chapterUrl) async {
    // Return sample page URLs (these would be real public domain comic pages)
    return [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Little_Nemo_1905-10-15.jpg/800px-Little_Nemo_1905-10-15.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Little_Nemo_1905-10-22.jpg/800px-Little_Nemo_1905-10-22.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Little_Nemo_1905-10-29.jpg/800px-Little_Nemo_1905-10-29.jpg',
    ];
  }

  @override
  bool validate() {
    return true;
  }

  List<MangaResult> _getSampleManga() {
    return [
      const MangaResult(
        title: 'Little Nemo in Slumberland',
        url: 'https://example.com/manga/little-nemo',
        coverImageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Little_Nemo_1905-10-15.jpg/400px-Little_Nemo_1905-10-15.jpg',
        description: 'Classic comic strip by Winsor McCay from the early 1900s',
        author: 'Winsor McCay',
        genres: ['Classic', 'Fantasy', 'Public Domain'],
        status: 'Completed',
      ),
      const MangaResult(
        title: 'The Yellow Kid',
        url: 'https://example.com/manga/yellow-kid',
        coverImageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Hogan%27s_Alley_comic.jpg/400px-Hogan%27s_Alley_comic.jpg',
        description: 'One of the first comic strips, from the 1890s',
        author: 'Richard F. Outcault',
        genres: ['Classic', 'Comedy', 'Public Domain'],
        status: 'Completed',
      ),
      const MangaResult(
        title: 'Krazy Kat',
        url: 'https://example.com/manga/krazy-kat',
        description: 'Surreal comic strip by George Herriman',
        author: 'George Herriman',
        genres: ['Classic', 'Surreal', 'Public Domain'],
        status: 'Completed',
      ),
    ];
  }
}
