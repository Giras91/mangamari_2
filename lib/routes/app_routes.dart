import 'package:flutter/material.dart';
import '../views/ai_custom_source_generator_view.dart';

/// Navigation routes for MangaMari
class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String library = '/library';
  static const String settings = '/settings';
  static const String aiSourceGenerator = '/ai-source-generator';
  static const String mangaDetails = '/manga-details';
  static const String reader = '/reader';
  static const String sourceManager = '/source-manager';

  /// Route generator for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case aiSourceGenerator:
        return MaterialPageRoute(
          builder: (context) => const AICustomSourceGeneratorView(),
          settings: settings,
        );
      
      // Add other routes here as they're implemented
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }

  /// Helper to navigate to AI Source Generator
  static void navigateToAISourceGenerator(BuildContext context) {
    Navigator.pushNamed(context, aiSourceGenerator);
  }

  /// Helper to navigate to Source Manager
  static void navigateToSourceManager(BuildContext context) {
    Navigator.pushNamed(context, sourceManager);
  }
}
