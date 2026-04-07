import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/platform/orientation_lock.dart';
import 'core/routing/app_router.dart';
import 'core/routing/router_refresh_notifier.dart';
import 'core/theme/app_theme.dart';
import 'core/di/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Dark status bar *icons* on light surfaces (fixes light-on-light contrast).
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await lockLandscape();
  runApp(const ValetMasterApp());
}

class ValetMasterApp extends StatelessWidget {
  const ValetMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MaterialApp(
        title: 'Valet Master',
        theme: appTheme(),
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
  }
}
