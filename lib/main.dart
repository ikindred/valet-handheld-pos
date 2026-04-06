import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/platform/orientation_lock.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
              final router = createAppRouter(context);
              return Router.withConfig(config: router);
            },
          ),
        ),
      ),
    );
  }
}
