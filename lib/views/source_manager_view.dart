  // Clean reset of file to fix broken structure
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../source_extensions/manager/source_manager.dart';
  import '../source_extensions/models/source_definition.dart';
  import '../source_extensions/compliance/legal_compliance_checker.dart';

  final sourceManagerProvider = Provider<SourceManager>((ref) => SourceManager());
  final installedSourcesProvider = FutureProvider<List<SourceDefinition>>((ref) async {
    final manager = ref.read(sourceManagerProvider);
    return manager.installedSources;
  });
  final sourceMetadataProvider = Provider<List<SourceMetadata>>((ref) {
    final manager = ref.read(sourceManagerProvider);
    return manager.sourceMetadata;
  });

  class SourceManagerView extends ConsumerStatefulWidget {
    const SourceManagerView({super.key});

    @override
    ConsumerState<SourceManagerView> createState() => _SourceManagerViewState();
  }

  class _SourceManagerViewState extends ConsumerState<SourceManagerView> {
  // ...existing code...
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  bool _isInstalling = false;
  String? _installMessage;

    @override
    Widget build(BuildContext context) {
      final installedSourcesAsync = ref.watch(installedSourcesProvider);
      final metadata = ref.watch(sourceMetadataProvider);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Source Manager'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Compliance Settings',
              onPressed: _showComplianceSettings,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<SourceType>(
                key: const ValueKey('sourceDropdown'),
                value: SourceType.jsonConfigured,
                items: SourceType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (_) {},
                hint: const Text('Select Source Type'),
              ),
            ),
            Expanded(
              child: installedSourcesAsync.when(
                data: (sources) => _buildSourceList(sources, metadata),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading sources: $e')),
              ),
            ),
          ],
        ),
      );
    }
    void _showInstallDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Install Source'),
          content: SizedBox(
            width: double.maxFinite,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'From URL'),
                      Tab(text: 'From JSON'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildUrlInstallTab(),
                        _buildJsonInstallTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('installDialogCancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('installDialogConfirm'),
              onPressed: _isInstalling ? null : _installSource,
              child: _isInstalling 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Install'),
            ),
          ],
        ),
      );
    }

  // ...existing code...

  Widget _buildSourceList(List<SourceDefinition> sources, List<SourceMetadata> metadata) {
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No sources installed'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const ValueKey('installSourceButton'),
              onPressed: _showInstallDialog,
              icon: const Icon(Icons.add),
              label: const Text('Install Source'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final meta = metadata.firstWhere(
          (m) => m.id == source.id,
          orElse: () => SourceMetadata(
            id: source.id,
            name: source.name,
            version: source.version,
            type: source.type,
            downloadUrl: '',
            installedAt: DateTime.now(),
          ),
        );
        return _buildSourceCard(source, meta);
      },
    );
  }

  Widget _buildSourceCard(SourceDefinition source, SourceMetadata metadata) {
    final complianceResult = LegalComplianceChecker.checkCompliance(source.baseUrl);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        key: ValueKey('sourceCard_${source.id}'),
        leading: CircleAvatar(
          backgroundColor: metadata.isEnabled ? Colors.green : Colors.grey,
          child: Icon(
            _getSourceTypeIcon(source.type),
            color: Colors.white,
          ),
        ),
        title: Text(source.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${source.version} • ${source.language.toUpperCase()}'),
            if (!complianceResult.isCompliant)
              Text(
                '⚠️ ${complianceResult.message}',
                style: TextStyle(
                  color: complianceResult.level == ComplianceLevel.unsafe 
                      ? Colors.red 
                      : Colors.orange,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          key: ValueKey('sourceCardMenu_${source.id}'),
          onSelected: (action) => _handleSourceAction(action, source, metadata),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: metadata.isEnabled ? 'disable' : 'enable',
              child: Text(metadata.isEnabled ? 'Disable' : 'Enable'),
            ),
            if (metadata.downloadUrl.isNotEmpty)
              const PopupMenuItem(
                value: 'update',
                child: Text('Update'),
              ),
            const PopupMenuItem(
              value: 'uninstall',
              child: Text('Uninstall'),
            ),
          ],
        ),
        onTap: () => _showSourceDetails(source, metadata),
      ),
    );
  }

  IconData _getSourceTypeIcon(SourceType type) {
    switch (type) {
      case SourceType.jsonConfigured:
        return Icons.code;
      case SourceType.htmlScraping:
        return Icons.web;
      case SourceType.externalExtension:
        return Icons.extension;
    }
  }

  void _handleSourceAction(String action, SourceDefinition s, SourceMetadata m) async {
    final manager = ref.read(sourceManagerProvider);
    switch (action) {
      case 'enable':
      case 'disable':
        await manager.setSourceEnabled(s.id, action == 'enable');
        ref.invalidate(installedSourcesProvider);
        ref.invalidate(sourceMetadataProvider);
        break;
      case 'update':
        await _updateSource(s.id);
        break;
      case 'uninstall':
        await _uninstallSource(s.id);
        break;
    }
  }

  // ...existing code...

  Widget _buildUrlInstallTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            key: const ValueKey('installUrlField'),
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Source URL',
              hintText: 'https://example.com/source.json',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_installMessage != null)
            Text(
              _installMessage!,
              style: TextStyle(
                color: _installMessage!.contains('Error') ? Colors.red : Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJsonInstallTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('installJsonField'),
              controller: _jsonController,
              decoration: const InputDecoration(
                labelText: 'JSON Configuration',
                hintText: 'Paste JSON source configuration here...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              expands: true,
            ),
          ),
          const SizedBox(height: 16),
          if (_installMessage != null)
            Text(
              _installMessage!,
              style: TextStyle(
                color: _installMessage!.contains('Error') ? Colors.red : Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  void _installSource() async {
    setState(() {
      _isInstalling = true;
      _installMessage = null;
    });

    final manager = ref.read(sourceManagerProvider);
    InstallResult result;
    final dialogContext = context;

    if (_urlController.text.isNotEmpty) {
      result = await manager.installFromUrl(_urlController.text);
    } else if (_jsonController.text.isNotEmpty) {
      result = await manager.installFromJson(_jsonController.text);
    } else {
      result = const InstallResult(
        success: false,
        message: 'Please provide either a URL or JSON configuration',
      );
    }

    setState(() {
      _isInstalling = false;
      _installMessage = result.message;
    });

    if (result.success) {
      ref.invalidate(installedSourcesProvider);
      ref.invalidate(sourceMetadataProvider);
      if (result.complianceWarning != null) {
        _showComplianceWarning(result.complianceWarning!);
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(dialogContext).pop(); // FIX: use captured context
        }
      });
    }
  }

  void _showComplianceWarning(String warning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Compliance Warning'),
        content: Text(warning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showComplianceSettings() {
    showDialog(
      context: context,
      builder: (context) => _complianceSettingsDialog(),
    );
  }

  Widget _complianceSettingsDialog() {
    final manager = ref.read(sourceManagerProvider);
    var settings = manager.complianceSettings;
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Compliance Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              key: const ValueKey('complianceUnknownSwitch'),
              title: const Text('Allow Unknown Sources'),
              subtitle: const Text("Allow sources that haven't been verified"),
              value: settings.allowUnknownSources,
              onChanged: (v) => setState(() => settings = settings.copyWith(allowUnknownSources: v)),
            ),
            SwitchListTile(
              key: const ValueKey('complianceUnsafeSwitch'),
              title: const Text('Allow Unsafe Sources'),
              subtitle: const Text('Allow sources known to have copyrighted content'),
              value: settings.allowUnsafeSources,
              onChanged: (v) => setState(() => settings = settings.copyWith(allowUnsafeSources: v)),
            ),
            SwitchListTile(
              key: const ValueKey('complianceWarningSwitch'),
              title: const Text('Show Warnings'),
              subtitle: const Text('Display compliance warnings'),
              value: settings.showWarnings,
              onChanged: (v) => setState(() => settings = settings.copyWith(showWarnings: v)),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('complianceCancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('complianceSave'),
            onPressed: () async {
              await manager.updateComplianceSettings(settings);
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSourceDetails(SourceDefinition source, SourceMetadata metadata) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(source.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${source.id}'),
            Text('Version: ${source.version}'),
            Text('Language: ${source.language}'),
            Text('Base URL: ${source.baseUrl}'),
            Text('Type: ${source.type.name}'),
            Text('NSFW: ${source.isNsfw ? 'Yes' : 'No'}'),
            Text('Installed: ${metadata.installedAt.toString().substring(0, 16)}'),
            if (metadata.lastUpdated != null)
              Text('Last Updated: ${metadata.lastUpdated.toString().substring(0, 16)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSource(String sourceId) async {
    final manager = ref.read(sourceManagerProvider);
    final result = await manager.updateSource(sourceId);
    if (!mounted) return;
    if (result.success) {
      ref.invalidate(installedSourcesProvider);
      ref.invalidate(sourceMetadataProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update source: ${result.message}')),
      );
    }
  }

  Future<void> _uninstallSource(String sourceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Source'),
        content: const Text('Are you sure you want to uninstall this source?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      final manager = ref.read(sourceManagerProvider);
      final success = await manager.uninstallSource(sourceId);
      if (!mounted) return;
      if (success) {
        ref.invalidate(installedSourcesProvider);
        ref.invalidate(sourceMetadataProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source uninstalled successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to uninstall source')),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _jsonController.dispose();
    super.dispose();
  }
}

