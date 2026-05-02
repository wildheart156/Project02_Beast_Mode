import 'package:beast_mode_fitness/shared/widgets/theme_toggle_button.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:beast_mode_fitness/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme toggle button switches between light and dark modes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = BeastModeThemeController(preferences: preferences);
    await controller.load();

    await tester.pumpWidget(_ThemeHarness(controller: controller));

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    expect(find.text(Brightness.light.name), findsOneWidget);

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    expect(find.text(Brightness.dark.name), findsOneWidget);
    expect(preferences.getString('beast_mode_theme_mode'), ThemeMode.dark.name);
  });
}

class _ThemeHarness extends StatefulWidget {
  const _ThemeHarness({required this.controller});

  final BeastModeThemeController controller;

  @override
  State<_ThemeHarness> createState() => _ThemeHarnessState();
}

class _ThemeHarnessState extends State<_ThemeHarness> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleThemeChanged);
  }

  @override
  void didUpdateWidget(covariant _ThemeHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleThemeChanged);
      widget.controller.addListener(_handleThemeChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: widget.controller,
      child: MaterialApp(
        theme: BeastModeTheme.light(),
        darkTheme: BeastModeTheme.dark(),
        themeMode: widget.controller.themeMode,
        home: Scaffold(
          appBar: AppBar(actions: const [ThemeToggleButton()]),
          body: Builder(
            builder: (context) {
              return Text(Theme.of(context).brightness.name);
            },
          ),
        ),
      ),
    );
  }
}
