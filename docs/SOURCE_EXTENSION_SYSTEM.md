# MangaMari Source Extension System

## Overview

MangaMari implements a modular source extension system inspired by Kotatsu and Tachiyomi, allowing users to add new manga sources without recompiling the app. The system is designed with legal compliance in mind and supports multiple source types.

## Architecture

### Core Components

1. **SourceDefinition** - Abstract base class for all source types
2. **SourceManager** - Manages installation, updates, and removal of sources
3. **LegalComplianceChecker** - Validates source safety and licensing
4. **JSONConfiguredSource** - Declarative JSON-based sources

### Source Types

#### 1. JSON-Configured Sources
The most common and easiest to create. Sources are defined using JSON configuration files with CSS selectors.

**Example Configuration:**
```json
{
  "id": "example_manga_site",
  "name": "Example Manga Site",
  "version": "1.0.0",
  "baseUrl": "https://example.com",
  "language": "en",
  "isNsfw": false,
  "supportedFeatures": ["latest", "popular", "search"],
  
  "popularPage": {
    "url": "{baseUrl}/popular?page={page}",
    "selectors": {
      "mangaItem": ".manga-item",
      "title": ".manga-title",
      "url": "a",
      "coverImage": "img",
      "description": ".manga-desc"
    }
  },
  
  "searchPage": {
    "url": "{baseUrl}/search?q={query}&page={page}",
    "selectors": {
      "mangaItem": ".manga-item",
      "title": ".manga-title",
      "url": "a",
      "coverImage": "img"
    }
  },
  
  "detailsPage": {
    "selectors": {
      "title": "h1.manga-title",
      "description": ".manga-description",
      "coverImage": ".manga-cover img",
      "author": ".manga-author",
      "genres": ".manga-genres a",
      "chapterList": ".chapter-list li",
      "chapterTitle": ".chapter-title",
      "chapterUrl": "a",
      "chapterNumber": ".chapter-number"
    }
  },
  
  "readerPage": {
    "selectors": {
      "pageImages": ".page-image img, .reader-image"
    }
  }
}
```

#### 2. HTML Scraping Sources (Future)
Direct Dart implementation for complex sites that need custom logic.

#### 3. External Extensions (Future)
Bridge for Kotlin/Tachiyomi extensions using platform channels.

### Legal Compliance System

The system includes built-in legal compliance checking:

#### Safe Sources (Automatically Allowed)
- MangaDex (mangadex.org) - Open source, community-driven
- Archive.org - Public domain works
- Project Gutenberg - Public domain books/manga
- Official platforms (Viz, Shueisha, etc.)

#### Unsafe Sources (Blocked by Default)
- Known piracy sites are automatically flagged
- Users can override with explicit consent

#### Unknown Sources
- New sources require user verification
- Compliance warnings are displayed
- Users can add to safe list after verification

### Installation Methods

1. **From URL** - Install directly from a source configuration URL
2. **From JSON** - Paste configuration directly
3. **From Repository** - Future: Install from curated repositories

### File Structure

```
lib/source_extensions/
├── models/
│   └── source_definition.dart       # Core models and interfaces
├── sources/
│   └── json_configured_source.dart  # JSON-based source implementation
├── manager/
│   └── source_manager.dart          # Source management logic
├── compliance/
│   └── legal_compliance_checker.dart # Legal compliance system
└── ui/
    └── source_manager_view.dart     # Source management UI

examples/
└── archive_org_manga_source.json   # Example source definition
```

## Creating New Sources

### Step 1: Analyze the Target Site

1. Identify the manga list pages (popular, latest, search)
2. Find CSS selectors for manga items and their properties
3. Analyze manga detail pages for metadata and chapter lists
4. Check reader pages for image loading patterns

### Step 2: Create JSON Configuration

Use the template above and fill in the appropriate selectors:

- **mangaItem**: Container for each manga in lists
- **title**: Manga title selector
- **url**: Link to manga details (usually an `<a>` tag)
- **coverImage**: Manga cover image
- **description**: Manga description/summary
- **chapterList**: Container for each chapter
- **pageImages**: Chapter page images

### Step 3: Test and Validate

1. Install the source using the Source Manager
2. Test popular/latest/search functionality
3. Verify manga details load correctly
4. Check that chapters and pages work

### Step 4: Handle URL Patterns

Use placeholders in URLs:
- `{baseUrl}` - Source base URL
- `{page}` - Page number for pagination
- `{query}` - Search query (URL encoded automatically)

## Best Practices

### Legal Compliance
1. Only create sources for sites with proper licensing
2. Verify copyright status before adding sources
3. Include clear disclaimers about content licensing
4. Respect robots.txt and rate limiting

### Technical Guidelines
1. Use specific CSS selectors to avoid false matches
2. Handle pagination correctly
3. Include error handling for missing elements
4. Test with multiple manga to ensure reliability
5. Keep selectors simple and maintainable

### Source Configuration
1. Use semantic IDs (e.g., "site_name_manga")
2. Follow semantic versioning for updates
3. Include comprehensive feature support
4. Add appropriate language tags

## Extension API

### Core Methods
All sources must implement these methods:

```dart
Future<List<MangaResult>> getPopularManga({int page = 1});
Future<List<MangaResult>> getLatestManga({int page = 1});
Future<List<MangaResult>> searchManga(String query, {int page = 1});
Future<MangaDetails> getMangaDetails(String mangaUrl);
Future<List<String>> getChapterPages(String chapterUrl);
bool validate();
```

### Data Models

**MangaResult** - Basic manga information for lists
**MangaDetails** - Complete manga information with chapters
**ChapterInfo** - Chapter metadata
**SourceMetadata** - Source installation information

## Future Enhancements

1. **Repository System** - Curated source repositories
2. **Kotlin Extensions** - Bridge to Tachiyomi extensions
3. **Advanced Scraping** - JavaScript execution for SPA sites
4. **Caching Layer** - Smart caching for better performance
5. **Source Templates** - Common patterns for faster development
6. **Auto-Detection** - Automatic selector discovery
7. **Rating System** - Community ratings for sources
8. **Update Notifications** - Automatic source updates

## Security Considerations

1. All network requests are sandboxed
2. No arbitrary code execution in JSON sources
3. Input validation for all configuration fields
4. Rate limiting to prevent abuse
5. User consent for unknown sources
6. Clear separation between safe and unsafe content

## Contributing

To add new sources to the official collection:

1. Verify the site has proper licensing
2. Create a complete JSON configuration
3. Test thoroughly with multiple manga
4. Submit via pull request with documentation
5. Include compliance verification

The source system is designed to be both powerful and safe, enabling community-driven expansion while protecting users and respecting copyright law.
