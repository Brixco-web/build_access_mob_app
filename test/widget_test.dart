import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:build_access_mob_app/app.dart';

void main() {
  testWidgets('App loads initialization screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ApexApp()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
