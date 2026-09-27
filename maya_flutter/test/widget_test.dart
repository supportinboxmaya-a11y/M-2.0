// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maya_pro/main.dart';

void main() {
  testWidgets('MayaApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MayaApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}