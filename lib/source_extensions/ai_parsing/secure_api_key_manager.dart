import 'dart:convert';
import 'package:hive/hive.dart';
import 'ai_provider_interface.dart';

/// Secure storage and management of AI provider API keys
class SecureAPIKeyManager {
  static const String _boxName = 'ai_api_keys';
  static const String _configBoxName = 'ai_provider_configs';
  
  static Box<String>? _keysBox;
  static Box<String>? _configBox;
  
  /// Initialize secure storage
  static Future<void> initialize() async {
    _keysBox = await Hive.openBox<String>(_boxName);
    _configBox = await Hive.openBox<String>(_configBoxName);
  }

  /// Store API key securely (encrypted)
  static Future<void> storeAPIKey({
    required AIProvider provider,
    required String apiKey,
  }) async {
    await _ensureInitialized();
    
    final encryptedKey = _encryptAPIKey(apiKey);
    await _keysBox!.put(provider.id, encryptedKey);
  }

  /// Retrieve API key (decrypted)
  static Future<String?> getAPIKey(AIProvider provider) async {
    await _ensureInitialized();
    
    final encryptedKey = _keysBox!.get(provider.id);
    if (encryptedKey == null) return null;
    
    return _decryptAPIKey(encryptedKey);
  }

  /// Store provider configuration
  static Future<void> storeProviderConfig({
    required AIProvider provider,
    required AIProviderConfig config,
  }) async {
    await _ensureInitialized();
    
    // Don't store API key in config (stored separately)
    final configWithoutKey = AIProviderConfig(
      provider: config.provider,
      apiKey: '', // Stored separately
      endpoint: config.endpoint,
      headers: config.headers,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
    );
    
    final configJson = jsonEncode(configWithoutKey.toJson());
    await _configBox!.put(provider.id, configJson);
  }

  /// Retrieve provider configuration
  static Future<AIProviderConfig?> getProviderConfig(AIProvider provider) async {
    await _ensureInitialized();
    
    final configJson = _configBox!.get(provider.id);
    if (configJson == null) return null;
    
    try {
      final configData = jsonDecode(configJson) as Map<String, dynamic>;
      final apiKey = await getAPIKey(provider) ?? '';
      
      configData['apiKey'] = apiKey;
      return AIProviderConfig.fromJson(configData);
    } catch (e) {
      return null;
    }
  }

  /// Remove API key and configuration
  static Future<void> removeProvider(AIProvider provider) async {
    await _ensureInitialized();
    
    await _keysBox!.delete(provider.id);
    await _configBox!.delete(provider.id);
  }

  /// Get list of configured providers
  static Future<List<AIProvider>> getConfiguredProviders() async {
    await _ensureInitialized();
    
    final configuredIds = _keysBox!.keys.toList();
    return AIProvider.values
        .where((provider) => configuredIds.contains(provider.id))
        .toList();
  }

  /// Check if provider is configured
  static Future<bool> isProviderConfigured(AIProvider provider) async {
    await _ensureInitialized();
    return _keysBox!.containsKey(provider.id);
  }

  /// Validate stored API key for a provider
  static Future<bool> validateStoredAPIKey(AIProvider provider) async {
    final config = await getProviderConfig(provider);
    if (config == null || config.apiKey.isEmpty) return false;
    
    // This would use the appropriate provider implementation
    // For now, just check if key exists and has reasonable format
    return _isValidAPIKeyFormat(provider, config.apiKey);
  }

  /// Export configurations (without API keys) for backup
  static Future<Map<String, dynamic>> exportConfigs() async {
    await _ensureInitialized();
    
    final configs = <String, dynamic>{};
    for (final provider in AIProvider.values) {
      final config = await getProviderConfig(provider);
      if (config != null) {
        final exportConfig = config.toJson();
        exportConfig['apiKey'] = '[REDACTED]'; // Don't export keys
        configs[provider.id] = exportConfig;
      }
    }
    
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'configs': configs,
    };
  }

  /// Clear all stored data (use with caution)
  static Future<void> clearAll() async {
    await _ensureInitialized();
    
    await _keysBox!.clear();
    await _configBox!.clear();
  }

  // Private methods

  static Future<void> _ensureInitialized() async {
    if (_keysBox == null || _configBox == null) {
      await initialize();
    }
  }

  static String _encryptAPIKey(String apiKey) {
    // Simple encryption for demo - in production use proper encryption
    final bytes = utf8.encode(apiKey);
    final reversed = bytes.reversed.toList();
    final encoded = base64Encode(reversed);
    return encoded;
  }

  static String _decryptAPIKey(String encryptedKey) {
    // Simple decryption for demo - in production use proper decryption
    final decoded = base64Decode(encryptedKey);
    final reversed = decoded.reversed.toList();
    return utf8.decode(reversed);
  }

  static bool _isValidAPIKeyFormat(AIProvider provider, String apiKey) {
    switch (provider) {
      case AIProvider.claude:
        return apiKey.startsWith('sk-ant-') && apiKey.length > 20;
      case AIProvider.openai:
        return apiKey.startsWith('sk-') && apiKey.length > 20;
      case AIProvider.gemini:
        return apiKey.length > 20; // Gemini keys vary in format
      case AIProvider.localLlm:
        return true; // Local LLM might not need API key
    }
  }
}

/// Helper for managing provider-specific configurations
class AIProviderConfigHelper {
  /// Get default configuration for a provider
  static AIProviderConfig getDefaultConfig(AIProvider provider, {String apiKey = ''}) {
    switch (provider) {
      case AIProvider.claude:
        return AIProviderConfig(
          provider: provider,
          apiKey: apiKey,
          maxTokens: 4000,
          temperature: 0.1,
        );
      case AIProvider.openai:
        return AIProviderConfig(
          provider: provider,
          apiKey: apiKey,
          maxTokens: 4000,
          temperature: 0.1,
        );
      case AIProvider.gemini:
        return AIProviderConfig(
          provider: provider,
          apiKey: apiKey,
          maxTokens: 2000,
          temperature: 0.1,
        );
      case AIProvider.localLlm:
        return AIProviderConfig(
          provider: provider,
          apiKey: apiKey,
          endpoint: 'http://localhost:11434/api/generate', // Ollama default
          maxTokens: 2000,
          temperature: 0.1,
        );
    }
  }

  /// Validate configuration for a provider
  static List<String> validateConfig(AIProviderConfig config) {
    final errors = <String>[];

    if (config.apiKey.isEmpty && config.provider != AIProvider.localLlm) {
      errors.add('API key is required for ${config.provider.displayName}');
    }

    if (config.maxTokens <= 0) {
      errors.add('Max tokens must be greater than 0');
    }

    if (config.temperature < 0 || config.temperature > 2) {
      errors.add('Temperature must be between 0 and 2');
    }

    if (config.provider == AIProvider.localLlm && 
        (config.endpoint == null || config.endpoint!.isEmpty)) {
      errors.add('Endpoint is required for Local LLM');
    }

    return errors;
  }
}
