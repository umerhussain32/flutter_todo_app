// Smoke test: the app boots to its splash screen and shows branding.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todoapp/app.dart';

void main() {
  testWidgets('App boots to splash without hanging', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Do it now'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}
