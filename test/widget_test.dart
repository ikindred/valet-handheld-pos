import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valet_handheld_pos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ValetMasterApp builds and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ValetMasterApp());
    await tester.pump();
    expect(find.text('Valet Master'), findsOneWidget);
  });
}
