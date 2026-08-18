import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/startup/startup_splash_screen.dart';
import 'core/storage/local_storage_provider.dart';
import 'core/storage/shared_preferences_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _StartupBootstrap());
}

class _StartupBootstrap extends StatefulWidget {
  const _StartupBootstrap();

  @override
  State<_StartupBootstrap> createState() => _StartupBootstrapState();
}

class _StartupBootstrapState extends State<_StartupBootstrap> {
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _preferences,
      builder: (context, snapshot) {
        final preferences = snapshot.data;
        if (preferences == null) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: StartupSplashScreen(),
          );
        }

        return ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(
              SharedPreferencesStorage(preferences),
            ),
          ],
          child: const CombugasApp(),
        );
      },
    );
  }
}
