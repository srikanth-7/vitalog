import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/presentation/pages/profile_screen.dart';
import 'package:vitalog/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ListView(children: [child])));

void main() {
  testWidgets('signed in: identity card, then separate account rows',
      (tester) async {
    var signedOut = false;
    var deleteAsked = false;
    await tester.pumpWidget(_app(AccountSection(
        email: 'srikanth.v@akrivia.in',
        name: 'Srikanth V',
        members: 3,
        reports: 7,
        unsynced: 2,
        onSignIn: () {},
        onSignOut: () => signedOut = true,
        onDeleteAccount: () => deleteAsked = true)));

    expect(find.text('Srikanth V'), findsOneWidget);
    expect(find.text('srikanth.v@akrivia.in'), findsOneWidget);
    expect(find.text('7'), findsOneWidget); // reports tile
    final signOut = find.widgetWithText(ListTile, 'Sign out');
    final delete = find.widgetWithText(ListTile, 'Delete account');
    expect(signOut, findsOneWidget);
    expect(delete, findsOneWidget);
    expect(find.text('Your reports stay on this phone.'), findsOneWidget);
    // Delete sits in its own group, clearly apart from Sign out.
    expect(tester.getTopLeft(delete).dy - tester.getBottomLeft(signOut).dy,
        greaterThanOrEqualTo(12));

    await tester.tap(signOut);
    await tester.tap(delete);
    expect(signedOut, isTrue);
    expect(deleteAsked, isTrue);
  });

  testWidgets('signed out: one Sign in button, no account rows',
      (tester) async {
    var signIn = false;
    await tester.pumpWidget(_app(AccountSection(
        email: null,
        name: null,
        members: 1,
        reports: 0,
        unsynced: 0,
        onSignIn: () => signIn = true,
        onSignOut: () {},
        onDeleteAccount: () {})));

    expect(find.widgetWithText(ListTile, 'Sign out'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Delete account'), findsNothing);
    await tester.tap(find.text('Sign in'));
    expect(signIn, isTrue);
  });
}
