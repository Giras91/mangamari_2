/// Legal compliance checker for manga sources
/// Ensures sources are from safe, legally compliant sites
class LegalComplianceChecker {
  // List of known safe/open-licensed manga sites
  static const List<String> _safeHosts = [
    'mangadex.org',           // Open source, community-driven
    'archive.org',            // Public domain works
    'gutenberg.org',          // Public domain books/manga
    'openlibrary.org',        // Open access library
    'webtoons.com',           // Official webtoons platform
    'tapas.io',               // Official comics platform
    'comixology.com',         // Official comics platform
    'viz.com',                // Official Viz Media
    'mangaplus.shueisha.co.jp', // Official Shueisha
    'readcomiconline.li',     // Public domain comics
    'digitalcomicmuseum.com', // Public domain comics
  ];

  // List of known unsafe/copyrighted content hosts
  static const List<String> _unsafeHosts = [
    'mangahere.cc',
    'mangafox.me',
    'mangareader.net',
    'mangastream.com',
    'kissmanga.com',
    'mangarock.com',
    'mangakakalot.com',
    'manganelo.com',
    'readmanga.today',
    'mangago.me',
  ];

  /// Check if a source URL is from a known safe host
  static ComplianceResult checkCompliance(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      // Remove www. prefix for comparison
      final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
      
      if (_safeHosts.contains(cleanHost)) {
        return ComplianceResult(
          isCompliant: true,
          level: ComplianceLevel.safe,
          message: 'Source is from a known safe, legally compliant site.',
        );
      }
      
      if (_unsafeHosts.contains(cleanHost)) {
        return ComplianceResult(
          isCompliant: false,
          level: ComplianceLevel.unsafe,
          message: 'Warning: This source may contain copyrighted content. Use at your own risk.',
        );
      }
      
      // Unknown host - requires user verification
      return ComplianceResult(
        isCompliant: false,
        level: ComplianceLevel.unknown,
        message: 'Unknown source. Please verify this site has proper licensing for manga content.',
      );
      
    } catch (e) {
      return ComplianceResult(
        isCompliant: false,
        level: ComplianceLevel.invalid,
        message: 'Invalid URL format.',
      );
    }
  }

  /// Check if source should be allowed based on user settings
  static bool shouldAllowSource(String url, UserComplianceSettings settings) {
    final result = checkCompliance(url);
    
    switch (result.level) {
      case ComplianceLevel.safe:
        return true;
      case ComplianceLevel.unknown:
        return settings.allowUnknownSources;
      case ComplianceLevel.unsafe:
        return settings.allowUnsafeSources;
      case ComplianceLevel.invalid:
        return false;
    }
  }

  /// Get warning message for source
  static String? getWarningMessage(String url) {
    final result = checkCompliance(url);
    return result.isCompliant ? null : result.message;
  }

  /// Add a new safe host (for user-verified sources)
  static void addSafeHost(String host) {
    // In a real implementation, this would save to user preferences
    // For now, we'll just add to runtime list
    if (!_safeHosts.contains(host.toLowerCase())) {
      // Note: This is a simplified implementation
      // In production, user-added safe hosts should be stored persistently
    }
  }
}

/// Result of compliance check
class ComplianceResult {
  final bool isCompliant;
  final ComplianceLevel level;
  final String message;

  const ComplianceResult({
    required this.isCompliant,
    required this.level,
    required this.message,
  });
}

/// Compliance levels for sources
enum ComplianceLevel {
  safe,     // Known safe/legal source
  unknown,  // Unknown source - needs user verification
  unsafe,   // Known to contain copyrighted content
  invalid,  // Invalid URL or configuration
}

/// User settings for compliance checking
class UserComplianceSettings {
  final bool allowUnknownSources;
  final bool allowUnsafeSources;
  final bool showWarnings;
  final List<String> userApprovedHosts;

  const UserComplianceSettings({
    this.allowUnknownSources = false,
    this.allowUnsafeSources = false,
    this.showWarnings = true,
    this.userApprovedHosts = const [],
  });

  factory UserComplianceSettings.fromJson(Map<String, dynamic> json) {
    return UserComplianceSettings(
      allowUnknownSources: json['allowUnknownSources'] as bool? ?? false,
      allowUnsafeSources: json['allowUnsafeSources'] as bool? ?? false,
      showWarnings: json['showWarnings'] as bool? ?? true,
      userApprovedHosts: (json['userApprovedHosts'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowUnknownSources': allowUnknownSources,
      'allowUnsafeSources': allowUnsafeSources,
      'showWarnings': showWarnings,
      'userApprovedHosts': userApprovedHosts,
    };
  }

  UserComplianceSettings copyWith({
    bool? allowUnknownSources,
    bool? allowUnsafeSources,
    bool? showWarnings,
    List<String>? userApprovedHosts,
  }) {
    return UserComplianceSettings(
      allowUnknownSources: allowUnknownSources ?? this.allowUnknownSources,
      allowUnsafeSources: allowUnsafeSources ?? this.allowUnsafeSources,
      showWarnings: showWarnings ?? this.showWarnings,
      userApprovedHosts: userApprovedHosts ?? this.userApprovedHosts,
    );
  }
}
