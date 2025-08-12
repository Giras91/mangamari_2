import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes/app_routes.dart';
import '../widgets/update_checker.dart';

/// Settings page for MangaMari
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Update checker dialog (shows if update available)
          Builder(
            builder: (context) {
              return UpdateChecker(
                versionJsonUrl: 'https://Giras91.github.io/mangamari_2/version.json',
              );
            },
          ),
          _buildSourcesSection(context),
          const Divider(),
          _buildAppearanceSection(context),
          const Divider(),
          _buildDataSection(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSourcesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sources',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.source),
          title: const Text('Manage Sources'),
          subtitle: const Text('Add, remove, and configure manga sources'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => AppRoutes.navigateToSourceManager(context),
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: const Text('AI Source Generator'),
          subtitle: const Text('Create custom sources using AI'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => AppRoutes.navigateToAISourceGenerator(context),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: const Text('Choose app theme'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Theme Settings'),
                content: const Text('Theme selection coming soon.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.menu_book),
          title: const Text('Reader Settings'),
          subtitle: const Text('Configure reading experience'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reader Settings'),
                content: const Text('Reader customization coming soon.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Data & Storage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Downloads'),
          subtitle: const Text('Manage downloaded manga'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Downloads Management'),
                content: const Text('Downloads management coming soon.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.clear_all),
          title: const Text('Clear Cache'),
          subtitle: const Text('Free up storage space'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showClearCacheDialog(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About MangaMari'),
          subtitle: const Text('Version 1.0.0'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showAboutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.gavel),
          title: const Text('Legal'),
          subtitle: const Text('Terms, privacy, and licenses'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showLegalDialog(context),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached manga data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Placeholder for cache clearing logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared (placeholder)')),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MangaMari',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.menu_book, size: 48),
      children: [
        const Text('An open-source manga reader built with Flutter.'),
        const SizedBox(height: 16),
        const Text('Inspired by Kotatsu and designed for legal, open-source manga sources.'),
      ],
    );
  }

  void _showLegalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Information'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terms of Use',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'MangaMari is intended for use with legally licensed manga content only. '
                'Users are responsible for ensuring their sources comply with local copyright laws.',
              ),
              SizedBox(height: 16),
              Text(
                'Open Source Licenses',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This app is built with Flutter and uses various open-source packages. '
                'See the source code repository for full license information.',
              ),
              SizedBox(height: 16),
              Text(
                'Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'MangaMari does not host or distribute manga content. '
                'All content is sourced from external websites that users configure.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
