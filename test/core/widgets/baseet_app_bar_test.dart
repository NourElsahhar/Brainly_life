import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester,
    PreferredSizeWidget bar, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(appBar: bar),
      ),
    );
  }

  /// The logo image that is on screen.
  String shownLogo(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    return (image.image as AssetImage).assetName;
  }

  testWidgets('main: shows the logo and a Settings button', (tester) async {
    var opened = false;
    await pumpBar(tester, BaseetAppBar.main(onSettings: () => opened = true));

    expect(find.byType(Image), findsOneWidget); // the logo
    await tester.tap(find.byTooltip('Settings'));
    expect(opened, isTrue);
  });

  testWidgets('main: the light theme uses the light logo', (tester) async {
    await pumpBar(tester, const BaseetAppBar.main());

    expect(shownLogo(tester), BaseetAppBar.lightLogo);
  });

  testWidgets('main: the dark theme uses the dark logo', (tester) async {
    await pumpBar(tester, const BaseetAppBar.main(), theme: AppTheme.dark);

    expect(shownLogo(tester), BaseetAppBar.darkLogo);
  });

  testWidgets('inner: shows the title and its actions, no logo', (
    tester,
  ) async {
    await pumpBar(
      tester,
      BaseetAppBar.inner(
        title: 'Task',
        actions: [
          AppBarIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            filled: false,
            onPressed: () {},
          ),
        ],
      ),
    );

    expect(find.text('Task'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // no logo
    expect(find.byTooltip('Settings'), findsNothing);
  });

  testWidgets('the bar is 64 high, as in the design', (tester) async {
    await pumpBar(tester, const BaseetAppBar.main());

    expect(tester.getSize(find.byType(AppBar)).height, BaseetAppBar.height);
  });
}
