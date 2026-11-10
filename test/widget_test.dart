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
}
