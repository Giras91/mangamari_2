import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../source_extensions/ai_parsing/ai_provider_interface.dart';
import '../source_extensions/ai_parsing/secure_api_key_manager.dart';
import '../source_extensions/ai_parsing/providers/claude_provider.dart';
import '../source_extensions/models/source_definition.dart';
import '../source_extensions/sources/json_configured_source.dart';
import '../source_extensions/manager/source_manager.dart';
import '../source_extensions/compliance/legal_compliance_checker.dart';

/// Provider for AI-powered source generation state
final aiSourceGeneratorProvider = StateNotifierProvider<AISourceGeneratorNotifier, AISourceGeneratorState>((ref) {
  return AISourceGeneratorNotifier();
});

/// State for AI source generator
class AISourceGeneratorState {
  final String url;
  final String sourceName;
  final AIProvider? selectedProvider;
  final String apiKey;
  final bool isAnalyzing;
  final bool isGenerating;
  final String? error;
  final String? warning;
  final AIAnalysisResult? analysisResult;
  final JSONSourceConfig? generatedConfig;
  final List<MangaResult> previewManga;

  const AISourceGeneratorState({
    this.url = '',
    this.sourceName = '',
    this.selectedProvider,
    this.apiKey = '',
    this.isAnalyzing = false,
    this.isGenerating = false,
    this.error,
    this.warning,
    this.analysisResult,
    this.generatedConfig,
    this.previewManga = const [],
  });

  AISourceGeneratorState copyWith({
    String? url,
    String? sourceName,
    AIProvider? selectedProvider,
    String? apiKey,
    bool? isAnalyzing,
    bool? isGenerating,
    String? error,
    String? warning,
    AIAnalysisResult? analysisResult,
    JSONSourceConfig? generatedConfig,
    List<MangaResult>? previewManga,
  }) {
    return AISourceGeneratorState(
      url: url ?? this.url,
      sourceName: sourceName ?? this.sourceName,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      apiKey: apiKey ?? this.apiKey,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      warning: warning,
      analysisResult: analysisResult ?? this.analysisResult,
      generatedConfig: generatedConfig ?? this.generatedConfig,
      previewManga: previewManga ?? this.previewManga,
    );
  }
}

/// Notifier for AI source generator state
class AISourceGeneratorNotifier extends StateNotifier<AISourceGeneratorState> {
  AISourceGeneratorNotifier() : super(const AISourceGeneratorState());

  final Map<AIProvider, AIProviderInterface> _providers = {
    AIProvider.claude: ClaudeAIProvider(),
  };

  void updateUrl(String url) {
    state = state.copyWith(url: url, error: null);
  }

  void updateSourceName(String name) {
    state = state.copyWith(sourceName: name);
  }

  void updateProvider(AIProvider? provider) {
    state = state.copyWith(selectedProvider: provider);
  }

  void updateApiKey(String apiKey) {
    state = state.copyWith(apiKey: apiKey);
  }

  /// Analyze website URL with AI
  Future<void> analyzeWebsite() async {
    if (state.url.isEmpty || state.selectedProvider == null) {
      state = state.copyWith(error: 'Please provide URL and select AI provider');
      return;
    }

    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      // Check domain compliance first
      final complianceResult = LegalComplianceChecker.checkCompliance(state.url);
      if (!complianceResult.isCompliant) {
        state = state.copyWith(
          isAnalyzing: false,
          warning: 'Warning: ${complianceResult.message}',
        );
        // Continue but with warning
      }

      // Fetch HTML content
      final html = await _fetchHTML(state.url);
      
      // Get or create AI provider config
      final config = await _getProviderConfig();
      
      // Analyze with AI
      final provider = _providers[state.selectedProvider]!;
      final result = await provider.analyzeHTML(
        html: html,
        url: state.url,
        config: config,
      );

      if (result.success) {
        // Extract source name if not provided
        final sourceName = state.sourceName.isEmpty 
            ? (result.sourceName ?? _extractDomainName(state.url))
            : state.sourceName;

        state = state.copyWith(
          isAnalyzing: false,
          analysisResult: result,
          sourceName: sourceName,
        );
      } else {
        state = state.copyWith(
          isAnalyzing: false,
          error: result.error ?? 'Analysis failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Failed to analyze website: $e',
      );
    }
  }

  /// Generate source configuration from analysis
  Future<void> generateSourceConfig() async {
    final result = state.analysisResult;
    if (result == null || !result.success || result.selectors == null) {
      state = state.copyWith(error: 'No analysis result available');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    try {
      final config = _buildJSONSourceConfig(result, state.sourceName, state.url);
      
      state = state.copyWith(
        isGenerating: false,
        generatedConfig: config,
      );

      // Test the generated config
      await _testGeneratedConfig(config);

    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate source config: $e',
      );
    }
  }

  /// Install the generated source
  Future<bool> installGeneratedSource() async {
    final config = state.generatedConfig;
    if (config == null) {
      state = state.copyWith(error: 'No source configuration available');
      return false;
    }

    try {
      final sourceManager = SourceManager();
      await sourceManager.initialize();
      
      final configJson = jsonEncode(config.toJson());
      final result = await sourceManager.installFromJson(configJson);
      
      if (result.success) {
        // Clear state after successful installation
        state = const AISourceGeneratorState();
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to install source: $e');
      return false;
    }
  }

  /// Save API key securely
  Future<void> saveApiKey() async {
    if (state.selectedProvider != null && state.apiKey.isNotEmpty) {
      await SecureAPIKeyManager.storeAPIKey(
        provider: state.selectedProvider!,
        apiKey: state.apiKey,
      );
      
      final config = AIProviderConfigHelper.getDefaultConfig(
        state.selectedProvider!,
        apiKey: state.apiKey,
      );
      
      await SecureAPIKeyManager.storeProviderConfig(
        provider: state.selectedProvider!,
        config: config,
      );
    }
  }

  // Private methods

  Future<String> _fetchHTML(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL: ${response.statusCode}');
    }
    return response.body;
  }

  Future<AIProviderConfig> _getProviderConfig() async {
    if (state.selectedProvider == null) {
      throw Exception('No AI provider selected');
    }

    // Try to get stored config first
    final storedConfig = await SecureAPIKeyManager.getProviderConfig(state.selectedProvider!);
    if (storedConfig != null && storedConfig.apiKey.isNotEmpty) {
      return storedConfig;
    }

    // Use provided API key
    if (state.apiKey.isEmpty) {
      throw Exception('API key required');
    }

    return AIProviderConfigHelper.getDefaultConfig(
      state.selectedProvider!,
      apiKey: state.apiKey,
    );
  }

  String _extractDomainName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return 'Custom Source';
    }
  }

  JSONSourceConfig _buildJSONSourceConfig(
    AIAnalysisResult result, 
    String sourceName, 
    String baseUrl,
  ) {
    final selectors = result.selectors!;
    final uri = Uri.parse(baseUrl);
    final domain = uri.host;

    // Build manga list selectors
    final mangaListSelectors = MangaListSelectors(
      mangaItem: selectors['mangaList'] ?? '',
      title: selectors['mangaTitle'],
      url: selectors['mangaUrl'],
      coverImage: selectors['mangaCover'],
      description: selectors['mangaDescription'],
      genres: selectors['mangaGenres'],
    );

    // Build detail page selectors
    final detailSelectors = MangaDetailsSelectors(
      title: selectors['mangaTitle'],
      description: selectors['mangaDescription'],
      coverImage: selectors['mangaCover'],
      status: selectors['mangaStatus'],
      author: selectors['mangaAuthor'],
      genres: selectors['mangaGenres'],
      chapterList: selectors['chapterList'] ?? '',
      chapterTitle: selectors['chapterTitle'],
      chapterUrl: selectors['chapterUrl'],
      chapterNumber: selectors['chapterNumber'],
    );

    // Build reader selectors
    final readerSelectors = ReaderSelectors(
      pageImages: selectors['pageImages'] ?? 'img',
    );

    return JSONSourceConfig(
      id: domain.replaceAll('.', '_'),
      name: sourceName,
      version: '1.0.0',
      baseUrl: '${uri.scheme}://${uri.host}',
      language: 'en',
      supportedFeatures: ['search', 'latest'],
      popularPage: PageConfig(
        url: '{baseUrl}/',
        selectors: mangaListSelectors,
      ),
      latestPage: PageConfig(
        url: '{baseUrl}/latest',
        selectors: mangaListSelectors,
      ),
      searchPage: PageConfig(
        url: '{baseUrl}/search?q={query}',
        selectors: mangaListSelectors,
      ),
      detailsPage: DetailsPageConfig(
        selectors: detailSelectors,
      ),
      readerPage: ReaderPageConfig(
        selectors: readerSelectors,
      ),
    );
  }

  Future<void> _testGeneratedConfig(JSONSourceConfig config) async {
    try {
      final source = JSONConfiguredSource(config);
      
      // Test fetching popular manga
      final manga = await source.getPopularManga(page: 1);
      
      state = state.copyWith(previewManga: manga.take(5).toList());
    } catch (e) {
      // Testing failed but don't show error - config might still work
      state = state.copyWith(previewManga: []);
    }
  }
}

/// AI-powered Custom Source Generator UI
class AICustomSourceGeneratorView extends ConsumerWidget {
  const AICustomSourceGeneratorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiSourceGeneratorProvider);
    final notifier = ref.read(aiSourceGeneratorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Source Generator'),
        actions: [
          if (state.generatedConfig != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _installSource(context, notifier),
              tooltip: 'Install Source',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderSelection(state, notifier),
            const SizedBox(height: 24),
            _buildUrlInput(state, notifier),
            const SizedBox(height: 16),
            _buildSourceDetails(state, notifier),
            const SizedBox(height: 24),
            _buildAnalysisSection(context, state, notifier),
            if (state.warning != null) ...[
              const SizedBox(height: 16),
              _buildWarningCard(state.warning!),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(state.error!),
            ],
            if (state.analysisResult != null) ...[
              const SizedBox(height: 24),
              _buildAnalysisResults(state),
            ],
            if (state.generatedConfig != null) ...[
              const SizedBox(height: 24),
              _buildGeneratedConfig(state),
            ],
            if (state.previewManga.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildPreviewSection(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelection(AISourceGeneratorState state, AISourceGeneratorNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AIProvider>(
              value: state.selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Select AI Provider',
                border: OutlineInputBorder(),
              ),
              items: AIProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.displayName),
                );
              }).toList(),
              onChanged: notifier.updateProvider,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.apiKey,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your AI provider API key',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              onChanged: notifier.updateApiKey,
            ),
            const SizedBox(height: 8),
            Text(
              'Your API key is stored securely on your device only.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput(AISourceGeneratorState state, AISourceGeneratorNotifier notifier) {
    return TextFormField(
      initialValue: state.url,
      decoration: const InputDecoration(
        labelText: 'Manga Website URL',
        hintText: 'https://example-manga-site.com',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      onChanged: notifier.updateUrl,
    );
  }

  Widget _buildSourceDetails(AISourceGeneratorState state, AISourceGeneratorNotifier notifier) {
    return TextFormField(
      initialValue: state.sourceName,
      decoration: const InputDecoration(
        labelText: 'Source Name (Optional)',
        hintText: 'Will be auto-detected if empty',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.label),
      ),
      onChanged: notifier.updateSourceName,
    );
  }

  Widget _buildAnalysisSection(
    BuildContext context, 
    AISourceGeneratorState state, 
    AISourceGeneratorNotifier notifier,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.isAnalyzing || 
                       state.url.isEmpty || 
                       state.selectedProvider == null ||
                       state.apiKey.isEmpty
                ? null
                : notifier.analyzeWebsite,
            icon: state.isAnalyzing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(state.isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
          ),
        ),
        if (state.analysisResult != null && state.generatedConfig == null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isGenerating ? null : notifier.generateSourceConfig,
                icon: state.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.build),
                label: Text(state.isGenerating ? 'Generating...' : 'Generate Source'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWarningCard(String warning) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                warning,
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults(AISourceGeneratorState state) {
    final result = state.analysisResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (result.sourceName != null)
              Text('Detected Site: ${result.sourceName}'),
            if (result.sourceDescription != null)
              Text('Description: ${result.sourceDescription}'),
            const SizedBox(height: 12),
            Text('Detected Selectors:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...result.selectors!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedConfig(AISourceGeneratorState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated Source Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Source ID: ${state.generatedConfig!.id}'),
            Text('Source Name: ${state.generatedConfig!.name}'),
            Text('Base URL: ${state.generatedConfig!.baseUrl}'),
            const SizedBox(height: 12),
            Text(
              'The source configuration has been generated and is ready to install.',
              style: TextStyle(color: Colors.green[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(AISourceGeneratorState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview (Test Results)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...state.previewManga.map((manga) {
              return ListTile(
                leading: Icon(Icons.book),
                title: Text(manga.title),
                subtitle: manga.description?.isNotEmpty == true 
                    ? Text(
                        manga.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _installSource(BuildContext context, AISourceGeneratorNotifier notifier) async {
    final success = await notifier.installGeneratedSource();
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source installed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
