import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/source_definition.dart';
import '../sources/json_configured_source.dart';
import '../compliance/legal_compliance_checker.dart';

/// Manages installation, updating, and removal of manga sources
/// Similar to Kotatsu/Tachiyomi extension management
class SourceManager {
  static const String _sourcesFileName = 'installed_sources.json';
  static const String _sourceConfigsDir = 'source_configs';
  
  final List<SourceDefinition> _installedSources = [];
  final List<SourceMetadata> _sourceMetadata = [];
  
  UserComplianceSettings _complianceSettings = const UserComplianceSettings();

  /// Get all installed sources
  List<SourceDefinition> get installedSources => List.unmodifiable(_installedSources);
  
  /// Get source metadata
  List<SourceMetadata> get sourceMetadata => List.unmodifiable(_sourceMetadata);
  
  /// Get enabled sources only
  List<SourceDefinition> get enabledSources {
    return _installedSources.where((source) {
      final metadata = _sourceMetadata.firstWhere(
        (meta) => meta.id == source.id,
        orElse: () => SourceMetadata(
          id: source.id,
          name: source.name,
          version: source.version,
          type: source.type,
          downloadUrl: '',
          installedAt: DateTime.now(),
        ),
      );
      return metadata.isEnabled;
    }).toList();
  }

  /// Initialize source manager and load installed sources
  Future<void> initialize() async {
    await _loadComplianceSettings();
    await _loadInstalledSources();
  }

  /// Install a source from a JSON configuration
  Future<InstallResult> installFromJson(String configJson, {String? downloadUrl}) async {
    try {
      final config = JSONSourceConfig.fromJson(jsonDecode(configJson));
      
      // Check legal compliance
      final complianceResult = LegalComplianceChecker.checkCompliance(config.baseUrl);
      if (!complianceResult.isCompliant && 
          !LegalComplianceChecker.shouldAllowSource(config.baseUrl, _complianceSettings)) {
        return InstallResult(
          success: false,
          message: 'Source blocked by compliance check: ${complianceResult.message}',
          complianceWarning: complianceResult.message,
        );
      }

      // Validate configuration
      final source = JSONConfiguredSource(config);
      if (!source.validate()) {
        return InstallResult(
          success: false,
          message: 'Invalid source configuration',
        );
      }

      // Check if already installed
      final existingIndex = _installedSources.indexWhere((s) => s.id == source.id);
      if (existingIndex != -1) {
        // Update existing source
        _installedSources[existingIndex] = source;
        final metaIndex = _sourceMetadata.indexWhere((m) => m.id == source.id);
        if (metaIndex != -1) {
          _sourceMetadata[metaIndex] = _sourceMetadata[metaIndex].copyWith(
            version: source.version,
            lastUpdated: DateTime.now(),
          );
        }
      } else {
        // Install new source
        _installedSources.add(source);
        _sourceMetadata.add(SourceMetadata(
          id: source.id,
          name: source.name,
          version: source.version,
          type: source.type,
          downloadUrl: downloadUrl ?? '',
          installedAt: DateTime.now(),
          description: 'JSON configured source',
        ));
      }

      // Save configuration to disk
      await _saveSourceConfig(source.id, configJson);
      await _saveInstalledSources();

      return InstallResult(
        success: true,
        message: 'Source installed successfully',
        complianceWarning: complianceResult.isCompliant ? null : complianceResult.message,
      );

    } catch (e) {
      return InstallResult(
        success: false,
        message: 'Failed to install source: $e',
      );
    }
  }

  /// Install a source from a URL
  Future<InstallResult> installFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return InstallResult(
          success: false,
          message: 'Failed to download source: HTTP ${response.statusCode}',
        );
      }

      return await installFromJson(response.body, downloadUrl: url);
    } catch (e) {
      return InstallResult(
        success: false,
        message: 'Failed to download source: $e',
      );
    }
  }

  /// Uninstall a source
  Future<bool> uninstallSource(String sourceId) async {
    try {
      _installedSources.removeWhere((source) => source.id == sourceId);
      _sourceMetadata.removeWhere((meta) => meta.id == sourceId);
      
      await _deleteSourceConfig(sourceId);
      await _saveInstalledSources();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable a source
  Future<void> setSourceEnabled(String sourceId, bool enabled) async {
    final metaIndex = _sourceMetadata.indexWhere((meta) => meta.id == sourceId);
    if (metaIndex != -1) {
      _sourceMetadata[metaIndex] = _sourceMetadata[metaIndex].copyWith(isEnabled: enabled);
      await _saveInstalledSources();
    }
  }

  /// Update a source from its download URL
  Future<InstallResult> updateSource(String sourceId) async {
    final metadata = _sourceMetadata.firstWhere(
      (meta) => meta.id == sourceId,
      orElse: () => throw Exception('Source not found'),
    );

    if (metadata.downloadUrl.isEmpty) {
      return InstallResult(
        success: false,
        message: 'Source has no update URL',
      );
    }

    return await installFromUrl(metadata.downloadUrl);
  }

  /// Update compliance settings
  Future<void> updateComplianceSettings(UserComplianceSettings settings) async {
    _complianceSettings = settings;
    await _saveComplianceSettings();
  }

  /// Get compliance settings
  UserComplianceSettings get complianceSettings => _complianceSettings;

  /// Check for source updates
  Future<List<String>> checkForUpdates() async {
    final updatableSources = <String>[];
    
    for (final metadata in _sourceMetadata) {
      if (metadata.downloadUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(metadata.downloadUrl));
          if (response.statusCode == 200) {
            final config = JSONSourceConfig.fromJson(jsonDecode(response.body));
            if (_isNewerVersion(config.version, metadata.version)) {
              updatableSources.add(metadata.id);
            }
          }
        } catch (e) {
          // Ignore update check failures
        }
      }
    }
    
    return updatableSources;
  }

  // Private methods

  Future<void> _loadInstalledSources() async {
    try {
      final file = await _getSourcesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        final metadataList = data['metadata'] as List<dynamic>;
        _sourceMetadata.clear();
        _sourceMetadata.addAll(
          metadataList.map((json) => SourceMetadata.fromJson(json as Map<String, dynamic>))
        );

        // Load source configurations
        _installedSources.clear();
        for (final metadata in _sourceMetadata) {
          final config = await _loadSourceConfig(metadata.id);
          if (config != null) {
            final source = JSONConfiguredSource(config);
            _installedSources.add(source);
          }
        }
      }
    } catch (e) {
      // If loading fails, start with empty list
    }
  }

  Future<void> _saveInstalledSources() async {
    try {
      final file = await _getSourcesFile();
      final data = {
        'metadata': _sourceMetadata.map((meta) => meta.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Handle save error
    }
  }

  Future<JSONSourceConfig?> _loadSourceConfig(String sourceId) async {
    try {
      final configsDir = await _getSourceConfigsDir();
      final configFile = File(path.join(configsDir.path, '$sourceId.json'));
      
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        return JSONSourceConfig.fromJson(jsonDecode(content));
      }
    } catch (e) {
      // Handle load error
    }
    return null;
  }

  Future<void> _saveSourceConfig(String sourceId, String configJson) async {
    try {
      final configsDir = await _getSourceConfigsDir();
      await configsDir.create(recursive: true);
      
      final configFile = File(path.join(configsDir.path, '$sourceId.json'));
      await configFile.writeAsString(configJson);
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _deleteSourceConfig(String sourceId) async {
    try {
      final configsDir = await _getSourceConfigsDir();
      final configFile = File(path.join(configsDir.path, '$sourceId.json'));
      
      if (await configFile.exists()) {
        await configFile.delete();
      }
    } catch (e) {
      // Handle delete error
    }
  }

  Future<void> _loadComplianceSettings() async {
    try {
      final file = await _getComplianceSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _complianceSettings = UserComplianceSettings.fromJson(data);
      }
    } catch (e) {
      // Use default settings if loading fails
    }
  }

  Future<void> _saveComplianceSettings() async {
    try {
      final file = await _getComplianceSettingsFile();
      await file.writeAsString(jsonEncode(_complianceSettings.toJson()));
    } catch (e) {
      // Handle save error
    }
  }

  Future<File> _getSourcesFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(path.join(appDir.path, _sourcesFileName));
  }

  Future<Directory> _getSourceConfigsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, _sourceConfigsDir));
  }

  Future<File> _getComplianceSettingsFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(path.join(appDir.path, 'compliance_settings.json'));
  }

  bool _isNewerVersion(String newVersion, String currentVersion) {
    // Simple version comparison - in production, use a proper semver library
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final newPart = i < newParts.length ? newParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      
      if (newPart > currentPart) return true;
      if (newPart < currentPart) return false;
    }
    
    return false;
  }
}

/// Result of source installation
class InstallResult {
  final bool success;
  final String message;
  final String? complianceWarning;

  const InstallResult({
    required this.success,
    required this.message,
    this.complianceWarning,
  });
}

// Extension for SourceMetadata to add copyWith method
extension SourceMetadataExtension on SourceMetadata {
  SourceMetadata copyWith({
    String? id,
    String? name,
    String? version,
    SourceType? type,
    String? downloadUrl,
    bool? isEnabled,
    bool? isOfficial,
    DateTime? installedAt,
    DateTime? lastUpdated,
    String? description,
    List<String>? tags,
  }) {
    return SourceMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      type: type ?? this.type,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      isOfficial: isOfficial ?? this.isOfficial,
      installedAt: installedAt ?? this.installedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }
}
