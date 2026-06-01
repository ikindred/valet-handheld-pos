import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/logging/valet_log.dart';
import 'core/platform/orientation_lock.dart';
import 'core/routing/app_router.dart';
import 'core/routing/router_refresh_notifier.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/di/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await dotenv.load(fileName: '.env');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await lockLandscape();
  final themeNotifier = await ThemeNotifier.load();
  ValetLog.debug('main', 'bootstrap complete, running app');
  runApp(ValetMasterApp(themeNotifier: themeNotifier));
}

class ValetMasterApp extends StatelessWidget {
  const ValetMasterApp({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeNotifier>.value(
      value: themeNotifier,
      child: ListenableBuilder(
        listenable: themeNotifier,
        builder: (context, _) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: themeNotifier.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: MaterialApp(
              title: 'SPiD Parking Valet',
              theme: appTheme(),
              darkTheme: appDarkTheme(),
              themeMode: themeNotifier.themeMode,
              debugShowCheckedModeBanner: false,
              home: AppProviders(
                child: Builder(
                  builder: (context) {
                    final refresh = context.read<RouterRefreshNotifier>();
                    final router = createAppRouter(context, refresh);
                    return Router.withConfig(config: router);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
