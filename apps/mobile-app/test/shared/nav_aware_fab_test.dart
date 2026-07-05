import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/shared/widgets/nav_aware_fab.dart';

void main() {
  // Mirrors MainShellPage: extendBody shell whose body republishes the
  // nav-injected MediaQuery padding as NavBarLift.
  Widget shell({required Widget child, double navHeight = 100.0}) {
    return MaterialApp(
      home: Scaffold(
        extendBody: true,
        bottomNavigationBar: SizedBox(height: navHeight),
        body: Builder(
          builder: (context) => NavBarLift(
            lift: MediaQuery.of(context).padding.bottom,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('NavAwareFab lifts FAB above an extendBody bottom nav',
      (tester) async {
    const navHeight = 100.0;

    await tester.pumpWidget(
      shell(
        child: Scaffold(
          floatingActionButton: NavAwareFab(
            child: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final fabBottom = tester.getRect(find.byType(FloatingActionButton)).bottom;

    // The FAB must clear the nav bar entirely (16px standard margin above it).
    expect(fabBottom, screenHeight - navHeight - 16.0);
  });

  testWidgets('NavAwareFab is a no-op without the shell nav', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: NavAwareFab(
            child: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final fabBottom = tester.getRect(find.byType(FloatingActionButton)).bottom;

    // Standard 16px FAB margin from the bottom edge.
    expect(fabBottom, screenHeight - 16.0);
  });

  testWidgets('NavAwareFab lifts a body-Stack Positioned FAB too',
      (tester) async {
    const navHeight = 100.0;

    await tester.pumpWidget(
      shell(
        child: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              Positioned(
                bottom: 20,
                right: 16,
                child: NavAwareFab(
                  child: FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final fabBottom = tester.getRect(find.byType(FloatingActionButton)).bottom;

    expect(fabBottom, screenHeight - navHeight - 20.0);
  });
}
