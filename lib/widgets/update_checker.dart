import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker extends StatefulWidget {
  final String versionJsonUrl;
  const UpdateChecker({super.key, required this.versionJsonUrl});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  String? latestVersion;
  String? apkUrl;
  String? changelog;
  bool updateAvailable = false;
  bool checked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';

      final response = await http.get(Uri.parse(widget.versionJsonUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        latestVersion = data['latest_version'];
        apkUrl = data['apk_url'];
        changelog = data['changelog'];

        if (_isNewerVersion(latestVersion!, currentVersion)) {
          setState(() {
            updateAvailable = true;
            checked = true;
          });
        } else {
          setState(() {
            checked = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        checked = true;
      });
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split(RegExp(r'[.+]')).map(int.parse).toList();
    final currentParts = current.split(RegExp(r'[.+]')).map(int.parse).toList();
    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!checked || !updateAvailable) {
      return const SizedBox.shrink();
    }
    return AlertDialog(
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A new version ($latestVersion) is available!'),
          const SizedBox(height: 8),
          if (changelog != null)
            Text('Changelog:\n$changelog'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Download APK'),
          onPressed: () async {
            if (apkUrl != null) {
              final dialogContext = context;
              await launchUrl(Uri.parse(apkUrl!), mode: LaunchMode.externalApplication);
              if (mounted) {
                Navigator.of(dialogContext).pop();
              }
            }
          },
        ),
      ],
    );
  }
}
