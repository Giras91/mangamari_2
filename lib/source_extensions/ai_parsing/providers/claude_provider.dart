import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider_interface.dart';

/// Claude AI provider implementation for HTML analysis
class ClaudeAIProvider implements AIProviderInterface {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-sonnet-20240229';

  @override
  Future<AIAnalysisResult> analyzeHTML({
    required String html,
    required String url,
    required AIProviderConfig config,
  }) async {
    try {
      // Prepare HTML input
      final input = _prepareHTMLInput(html, url);
      
      // Build request
      final request = _buildClaudeRequest(input, config);
      
      // Send to Claude API
      final response = await http.post(
        Uri.parse(config.endpoint ?? _baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          ...config.headers,
        },
        body: jsonEncode(request),
      );

      if (response.statusCode != 200) {
        return AIAnalysisResult.error(
          'Claude API error: ${response.statusCode} - ${response.body}',
        );
      }

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseClaudeResponse(responseData);

    } catch (e) {
      return AIAnalysisResult.error('Failed to analyze HTML with Claude: $e');
    }
  }

  @override
  Future<bool> validateApiKey(AIProviderConfig config) async {
    try {
      final response = await http.post(
        Uri.parse(config.endpoint ?? _baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 10,
          'messages': [
            {
              'role': 'user',
              'content': 'Test API key validation.',
            }
          ],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Map<String, dynamic> getConfigRequirements() {
    return {
      'apiKey': {
        'required': true,
        'type': 'string',
        'description': 'Anthropic API key',
        'placeholder': 'sk-ant-...',
      },
      'endpoint': {
        'required': false,
        'type': 'string',
        'description': 'Custom API endpoint (optional)',
        'placeholder': 'https://api.anthropic.com/v1/messages',
      },
      'model': {
        'required': false,
        'type': 'string',
        'description': 'Claude model to use',
        'default': _model,
        'options': [
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307',
          'claude-3-opus-20240229',
        ],
      },
    };
  }

  HTMLAnalysisInput _prepareHTMLInput(String html, String url) {
    // Clean and prepare HTML for analysis
    final cleanedHTML = _cleanHTML(html);
    final title = _extractTitle(html);
    final metadata = _extractMetadata(html, url);
    final patterns = _detectPatterns(cleanedHTML);

    return HTMLAnalysisInput(
      url: url,
      title: title,
      cleanedHTML: cleanedHTML,
      metadata: metadata,
      detectedPatterns: patterns,
    );
  }

  String _cleanHTML(String html) {
    // Remove script tags, style tags, and comments
    String cleaned = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', 
            caseSensitive: false, multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', 
            caseSensitive: false, multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<!--.*?-->', 
            multiLine: true, dotAll: true), '');

    // Limit size for API (Claude has token limits)
    if (cleaned.length > 15000) {
      // Try to keep the most relevant parts
      final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>', 
          caseSensitive: false, multiLine: true, dotAll: true)
          .firstMatch(cleaned);
      
      if (bodyMatch != null) {
        cleaned = '<body>${bodyMatch.group(1)}</body>';
      }
      
      // If still too long, truncate
      if (cleaned.length > 15000) {
  cleaned = '${cleaned.substring(0, 15000)}...';
      }
    }

    return cleaned;
  }

  String _extractTitle(String html) {
    final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', 
        caseSensitive: false, multiLine: true)
        .firstMatch(html);
    
    return titleMatch?.group(1)?.trim() ?? 'Unknown Site';
  }

  Map<String, String> _extractMetadata(String html, String url) {
    final metadata = <String, String>{
      'url': url,
      'domain': Uri.parse(url).host,
    };

    // Extract common meta tags
    final metaTagRegex = RegExp(r'<meta[^>]+>', caseSensitive: false);
    final metaTags = metaTagRegex.allMatches(html);

    for (final match in metaTags) {
      final metaTag = match.group(0)!;
      final nameMatch = RegExp(
        r'name=["' "'" r']([^"' "'" r']+)["' "'" r']',
        caseSensitive: false,
      ).firstMatch(metaTag);
      final contentMatch = RegExp(
        r'content=["' "'" r']([^"' "'" r']+)["' "'" r']',
        caseSensitive: false,
      ).firstMatch(metaTag);

      if (nameMatch != null && contentMatch != null) {
        metadata[nameMatch.group(1)!] = contentMatch.group(1)!;
      }
    }

    return metadata;
  }

  List<String> _detectPatterns(String html) {
    final patterns = <String>[];

    // Common manga site patterns
    final commonPatterns = [
      r'class="[^"]*manga[^"]*"',
      r'class="[^"]*chapter[^"]*"',
      r'class="[^"]*cover[^"]*"',
      r'class="[^"]*title[^"]*"',
      r'data-[^=]*="[^"]*"',
    ];

    for (final pattern in commonPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(html)) {
        patterns.add(pattern);
      }
    }

    return patterns;
  }

  Map<String, dynamic> _buildClaudeRequest(
    HTMLAnalysisInput input, 
    AIProviderConfig config,
  ) {
    final prompt = AIPromptTemplate.buildAnalysisPrompt(input);

    return {
      'model': _model,
      'max_tokens': config.maxTokens,
      'temperature': config.temperature,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    };
  }

  AIAnalysisResult _parseClaudeResponse(Map<String, dynamic> response) {
    try {
      final content = response['content'] as List<dynamic>;
      if (content.isEmpty) {
        return AIAnalysisResult.error('Empty response from Claude');
      }

      final textContent = content.first['text'] as String;
      
      // Extract JSON from response (Claude might include explanation text)
      final jsonMatch = RegExp(r'\{.*\}', multiLine: true, dotAll: true)
          .firstMatch(textContent);
      
      if (jsonMatch == null) {
        return AIAnalysisResult.error('No JSON found in Claude response');
      }

      final analysisData = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final selectors = Map<String, String>.from(
        analysisData['selectors'] as Map<String, dynamic>? ?? {}
      );

      // Validate that we have minimum required selectors
      final requiredSelectors = ['mangaList', 'mangaTitle', 'mangaUrl'];
      final missingSelectors = requiredSelectors
          .where((selector) => !selectors.containsKey(selector) || selectors[selector] == null)
          .toList();

      if (missingSelectors.isNotEmpty) {
        return AIAnalysisResult.error(
          'Missing required selectors: ${missingSelectors.join(', ')}'
        );
      }

      return AIAnalysisResult.success(
        selectors: selectors,
        sourceName: analysisData['sourceName'] as String?,
        sourceDescription: analysisData['sourceDescription'] as String?,
        metadata: {
          'confidence': analysisData['confidence'],
          'notes': analysisData['notes'],
          'provider': 'claude',
        },
      );

    } catch (e) {
      return AIAnalysisResult.error('Failed to parse Claude response: $e');
    }
  }
}
