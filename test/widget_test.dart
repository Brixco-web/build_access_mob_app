import 'package:flutter_test/flutter_test.dart';
import 'package:build_access_mob_app/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ApexBuildingApp());
    expect(find.textContaining('Apex Building Accessories'), findsOneWidget);
  });
}
