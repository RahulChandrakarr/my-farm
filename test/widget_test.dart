import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:my_farm/core/supabase_config.dart';
import 'package:my_farm/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('App opens farm login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('My Farm'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
