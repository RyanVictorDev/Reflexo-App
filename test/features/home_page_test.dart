import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/app/app_theme.dart';
import 'package:reflexo/features/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('a tela inicial oferece jogar em um toque', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const HomePage()),
    );

    expect(find.text('Reflexo'), findsOneWidget);
    expect(find.text('Jogar'), findsOneWidget);

    await tester.tap(find.text('Jogar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Toque para trocar de faixa'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });
}
