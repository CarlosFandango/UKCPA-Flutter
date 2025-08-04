import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/router_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize GraphQL cache
  await initHiveForFlutter();
  
  // Initialize MCP Toolkit for debugging and testing
  // await McpToolkit.initialize();
  
  // Configure Stripe (temporarily disabled for iOS setup)
  // Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  // await Stripe.instance.applySettings();
  
  runApp(
    const ProviderScope(
      child: UKCPAApp(),
    ),
  );
}

class UKCPAApp extends ConsumerWidget {
  const UKCPAApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}