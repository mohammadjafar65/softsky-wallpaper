import 'package:awg_admin_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('admin app starts on the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AdminApp());
    await tester.pumpAndSettle();

    expect(find.text('SoftSky Admin'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
