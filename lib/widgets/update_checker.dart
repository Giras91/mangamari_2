import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker extends StatefulWidget {
  /// Compares two semantic version strings (e.g. '1.2.3+4').
  /// Returns 1 if [a] > [b], -1 if [a] < [b], 0 if equal.
  static int compareVersions(String a, String b) {
    final aParts = a.split(RegExp(r'[.+]')).map(int.parse).toList();
    final bParts = b.split(RegExp(r'[.+]')).map(int.parse).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal > bVal) return 1;
      if (aVal < bVal) return -1;
    }
    return 0;
  }
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

        final cmp = UpdateChecker.compareVersions(latestVersion!, currentVersion);
        if (cmp > 0) {
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
              Navigator.of(context).pop();
              await launchUrl(Uri.parse(apkUrl!), mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}
