import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_dimens.dart';
import 'features/pos/presentation/pos_adaptive_scaffold.dart';
import 'features/pos/providers/database_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: RetailPosApplication(),
    ),
  );
}

/// Root application widget configuring enterprise Material 3 theming.
class RetailPosApplication extends StatelessWidget {
  const RetailPosApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Retail POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.posLimeGreen,
          primary: AppColors.posLimeGreen,
          surface: const Color(0xFF1E1E1E),
          surfaceTint: Colors.transparent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF333333)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
        ),
        fontFamily: 'Segoe UI',
      ),
      home: const DatabaseInitGate(),
    );
  }
}

/// Fallback gate ensuring local Hive storage engine is initialized and ready
/// before rendering reactive catalog and cart panels.
class DatabaseInitGate extends ConsumerWidget {
  const DatabaseInitGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(databaseInitProvider);

    return initAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Starting Nexus POS Engine',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mounting offline Hive database and verifying catalog...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text(
                        'Database Initialization Failure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to open offline storage engine: $error\nCheck filesystem permissions.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => ref.refresh(databaseInitProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Mounting Engine'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      data: (_) => const PosAdaptiveScaffold(),
    );
  }
}
