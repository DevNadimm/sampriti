import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampriti/core/components/custom_cached_image.dart';
import 'package:sampriti/core/components/member_avatar.dart';

void main() {
  testWidgets('MemberAvatar renders fallback when photo is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(
            photo: null,
            fallbackText: 'S-101',
            size: 50,
          ),
        ),
      ),
    );

    expect(find.text('S-101'), findsOneWidget);
  });

  testWidgets('MemberAvatar renders CustomCachedImage when photo is a URL', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(
            photo: 'https://example.com/avatar.jpg',
            fallbackText: 'S-101',
            size: 50,
          ),
        ),
      ),
    );

    expect(find.byType(CustomCachedImage), findsOneWidget);
  });

  testWidgets('MemberAvatar renders rectangular avatar with border and foregroundDecoration', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberAvatar(
            photo: null,
            fallbackText: 'নমিনী',
            width: 84,
            height: 104,
            isCircle: false,
            borderRadius: 12,
            border: Border.all(color: Colors.amber, width: 2.5),
          ),
        ),
      ),
    );

    expect(find.text('নমিনী'), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.foregroundDecoration, isNotNull);
  });
}
