import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valet_handheld_pos/core/theme/theme_notifier.dart';
import 'package:valet_handheld_pos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ValetMasterApp builds and shows splash', (WidgetTester tester) async {
    final themeNotifier = await ThemeNotifier.load();
    await tester.pumpWidget(ValetMasterApp(themeNotifier: themeNotifier));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
  });
}
