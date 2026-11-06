import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/domain/entities/family_member.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_widgets.dart';

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

FamilyMember _member({Uint8List? photo}) => FamilyMember(
    id: 'm',
    name: 'Ravi Kumar',
    relation: 'Parent',
    initials: 'RK',
    colorValue: 0xFFD8EFE5,
    age: 61,
    photo: photo);

Widget _app(Widget child) =>
    MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('the avatar shows the photo instead of initials', (tester) async {
    await tester.pumpWidget(_app(MemberAvatar(member: _member(photo: _png))));
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isNotNull);
    expect(find.text('RK'), findsNothing);
  });

  testWidgets('without a photo the avatar shows initials', (tester) async {
    await tester.pumpWidget(_app(MemberAvatar(member: _member())));
    expect(find.text('RK'), findsOneWidget);
  });
}
