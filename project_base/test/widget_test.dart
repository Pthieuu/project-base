import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/controller/theme_controller.dart';
import 'package:project_base/main.dart';
import 'package:project_base/screens/splash_screen.dart';
import 'package:project_base/screens/main_screen.dart';
import 'package:project_base/services/user_session.dart';
import 'package:project_base/widgets/guest_access.dart';

void main() {
  testWidgets('app starts on the splash screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => LanguageController()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('signed-out users enter the app in guest mode', (tester) async {
    UserSession.user_id = null;
    UserSession.name = null;
    UserSession.email = null;
    UserSession.accessToken = null;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => LanguageController()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(GuestModeBanner), findsOneWidget);

    await tester.tap(find.byIcon(Icons.account_balance_wallet));
    await tester.pump();
    expect(find.byType(GuestAccessView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.insights));
    await tester.pump();
    expect(find.byType(GuestAccessView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
