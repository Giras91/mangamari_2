import 'dart:convert';

/// Supported AI providers for HTML parsing
enum AIProvider {
  claude('Claude', 'Anthropic Claude'),
  openai('OpenAI', 'OpenAI GPT'),
  localLlm('Local LLM', 'Local Language Model'),
  gemini('Gemini', 'Google Gemini');

  const AIProvider(this.id, this.displayName);
  final String id;
  final String displayName;
}

/// Configuration for AI provider API calls
class AIProviderConfig {
  final AIProvider provider;
  final String apiKey;
  final String? endpoint; // For local LLM or custom endpoints
  final Map<String, String> headers;
  final int maxTokens;
  final double temperature;

  const AIProviderConfig({
    required this.provider,
    required this.apiKey,
    this.endpoint,
    this.headers = const {},
    this.maxTokens = 4000,
    this.temperature = 0.1,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.id,
      'apiKey': apiKey,
      'endpoint': endpoint,
      'headers': headers,
      'maxTokens': maxTokens,
      'temperature': temperature,
    };
  }

  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      provider: AIProvider.values.firstWhere((p) => p.id == json['provider']),
      apiKey: json['apiKey'] as String,
      endpoint: json['endpoint'] as String?,
      headers: Map<String, String>.from(json['headers'] ?? {}),
      maxTokens: json['maxTokens'] as int? ?? 4000,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.1,
    );
  }
}

/// Result of AI HTML analysis
class AIAnalysisResult {
  final bool success;
  final String? error;
  final Map<String, String>? selectors;
  final String? sourceName;
  final String? sourceDescription;
  final Map<String, dynamic>? metadata;

  const AIAnalysisResult({
    required this.success,
    this.error,
    this.selectors,
    this.sourceName,
    this.sourceDescription,
    this.metadata,
  });

  factory AIAnalysisResult.success({
    required Map<String, String> selectors,
    String? sourceName,
    String? sourceDescription,
    Map<String, dynamic>? metadata,
  }) {
    return AIAnalysisResult(
      success: true,
      selectors: selectors,
      sourceName: sourceName,
      sourceDescription: sourceDescription,
      metadata: metadata,
    );
  }

  factory AIAnalysisResult.error(String error) {
    return AIAnalysisResult(
      success: false,
      error: error,
    );
  }
}

/// Abstract interface for AI providers
abstract class AIProviderInterface {
  /// Analyze HTML content and extract CSS selectors for manga sites
  Future<AIAnalysisResult> analyzeHTML({
    required String html,
    required String url,
    required AIProviderConfig config,
  });

  /// Validate API key for the provider
  Future<bool> validateApiKey(AIProviderConfig config);

  /// Get provider-specific configuration requirements
  Map<String, dynamic> getConfigRequirements();
}

/// HTML content prepared for AI analysis
class HTMLAnalysisInput {
  final String url;
  final String title;
  final String cleanedHTML;
  final Map<String, String> metadata;
  final List<String> detectedPatterns;

  const HTMLAnalysisInput({
    required this.url,
    required this.title,
    required this.cleanedHTML,
    this.metadata = const {},
    this.detectedPatterns = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'cleanedHTML': cleanedHTML,
      'metadata': metadata,
      'detectedPatterns': detectedPatterns,
    };
  }
}

/// Standard prompt template for AI analysis
class AIPromptTemplate {
  static const String htmlAnalysisPrompt = '''
You are an expert at analyzing manga/comic website HTML to extract CSS selectors for automated scraping. 

Analyze the provided HTML and extract CSS selectors for the following elements:

REQUIRED SELECTORS:
1. mangaList - Container for manga list items
2. mangaTitle - Individual manga titles
3. mangaUrl - Links to manga detail pages
4. mangaCover - Manga cover images
5. chapterList - Container for chapter lists (on detail pages)
6. chapterTitle - Individual chapter titles
7. chapterUrl - Links to chapter reading pages
8. pageImages - Manga page images (on reader pages)

OPTIONAL SELECTORS:
9. mangaDescription - Manga descriptions
10. mangaGenres - Genre tags
11. mangaStatus - Publication status
12. mangaAuthor - Author information
13. chapterNumber - Chapter numbers
14. chapterDate - Chapter release dates

INSTRUCTIONS:
- Return ONLY valid CSS selectors that exist in the provided HTML
- Test selectors for uniqueness and reliability
- Prefer class selectors over complex hierarchies
- Ensure selectors work for multiple items (use appropriate containers)
- If a selector doesn't exist, return null for that field

RESPONSE FORMAT (JSON only):
{
  "selectors": {
    "mangaList": "CSS_SELECTOR",
    "mangaTitle": "CSS_SELECTOR", 
    "mangaUrl": "CSS_SELECTOR",
    "mangaCover": "CSS_SELECTOR",
    "chapterList": "CSS_SELECTOR",
    "chapterTitle": "CSS_SELECTOR",
    "chapterUrl": "CSS_SELECTOR",
    "pageImages": "CSS_SELECTOR",
    "mangaDescription": "CSS_SELECTOR_OR_NULL",
    "mangaGenres": "CSS_SELECTOR_OR_NULL",
    "mangaStatus": "CSS_SELECTOR_OR_NULL",
    "mangaAuthor": "CSS_SELECTOR_OR_NULL",
    "chapterNumber": "CSS_SELECTOR_OR_NULL",
    "chapterDate": "CSS_SELECTOR_OR_NULL"
  },
  "sourceName": "DETECTED_SITE_NAME",
  "sourceDescription": "BRIEF_DESCRIPTION",
  "confidence": 0.0_TO_1.0,
  "notes": "ANY_IMPORTANT_OBSERVATIONS"
}

HTML TO ANALYZE:
''';

  static String buildAnalysisPrompt(HTMLAnalysisInput input) {
    return '''
$htmlAnalysisPrompt

URL: ${input.url}
TITLE: ${input.title}
METADATA: ${jsonEncode(input.metadata)}

HTML CONTENT:
${input.cleanedHTML}
''';
  }
}
