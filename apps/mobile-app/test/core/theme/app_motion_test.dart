import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/motion_service.dart';
import 'package:mali_up/core/theme/app_motion.dart';

void main() {
  tearDown(() {
    MotionService.reducedMotionNotifier.value = false;
  });

  testWidgets('fade-through uses the Mali Up primary transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => KeyedSubtree(
            key: const Key('motion-root'),
            child: AppMotion.fadeThrough(
              context,
              const AlwaysStoppedAnimation<double>(1),
              const AlwaysStoppedAnimation<double>(0),
              const SizedBox(key: Key('content')),
            ),
          ),
        ),
      ),
    );

    final motionRoot = find.byKey(const Key('motion-root'));
    expect(
      find.descendant(of: motionRoot, matching: find.byType(FadeTransition)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: motionRoot, matching: find.byType(ScaleTransition)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('content')), findsOneWidget);
  });

  testWidgets('platform reduced motion removes spatial transitions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => KeyedSubtree(
              key: const Key('motion-root'),
              child: AppMotion.sharedAxisHorizontal(
                context,
                const AlwaysStoppedAnimation<double>(1),
                const AlwaysStoppedAnimation<double>(0),
                const SizedBox(key: Key('content')),
              ),
            ),
          ),
        ),
      ),
    );

    final motionRoot = find.byKey(const Key('motion-root'));
    expect(
      find.descendant(of: motionRoot, matching: find.byType(SlideTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: motionRoot, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(find.byKey(const Key('content')), findsOneWidget);
  });

  testWidgets('in-app reduced motion removes spatial transitions', (
    tester,
  ) async {
    MotionService.reducedMotionNotifier.value = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => KeyedSubtree(
            key: const Key('motion-root'),
            child: AppMotion.rise(
              context,
              const AlwaysStoppedAnimation<double>(1),
              const AlwaysStoppedAnimation<double>(0),
              const SizedBox(key: Key('content')),
            ),
          ),
        ),
      ),
    );

    final motionRoot = find.byKey(const Key('motion-root'));
    expect(
      find.descendant(of: motionRoot, matching: find.byType(SlideTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: motionRoot, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(find.byKey(const Key('content')), findsOneWidget);
  });
}
