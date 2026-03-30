# 🚀 MaliUp Onboarding Feature

A premium, modern onboarding experience designed for African SaaS businesses. Features smooth animations, beautiful gradients, and an intuitive user journey.

## Features

✨ **Splash Screen**
- Gradient background animation
- Pulsing logo effect
- Smooth fade transitions
- Professional brand presentation

📱 **4 Onboarding Screens**
- Dashboard management intro
- Real-time analytics tracking
- Cloud sync capabilities
- Call-to-action finale

🎬 **Advanced Animations**
- Smooth page transitions
- Sequential element entrance animations
- Floating icon effects
- Chart growth visualization
- Micro-interactions

🎨 **Premium Design**
- Modern gradient colors (Deep Blue #0B5ED7 + Fresh Green #16C47F)
- Clean, minimal UI inspired by Stripe/Notion
- Responsive layout for all screen sizes
- Accessibility-first approach

## Quick Start

### 1. Import and Use

```dart
import 'package:mali_up/features/onboarding/presentation/screens/onboarding_flow.dart';

OnboardingFlow(
  onComplete: () {
    // Navigate to auth or main app
    context.go('/auth/login');
  },
)
```

### 2. Add to Routing

```dart
GoRoute(
  path: '/onboarding',
  builder: (context, state) => OnboardingFlow(
    onComplete: () => context.go('/dashboard'),
  ),
),
```

### 3. Check First Time Launch

```dart
final hasCompleted = ref.watch(hasCompletedOnboardingProvider);

if (!hasCompleted) {
  // Show onboarding
} else {
  // Show main app
}
```

## File Structure

```
lib/features/onboarding/
├── core/
│   └── onboarding_colors.dart           # Brand colors & gradients
├── models/
│   └── onboarding_model.dart            # Screen data models
├── providers/
│   └── onboarding_provider.dart         # State management (Riverpod)
├── presentation/
│   ├── screens/
│   │   ├── splash_screen.dart           # Animated splash (2.5s)
│   │   ├── onboarding_screen.dart       # Main 4-screen flow
│   │   └── onboarding_flow.dart         # Master controller
│   └── widgets/
│       └── animated_widgets.dart        # Reusable animations
├── ONBOARDING_DESIGN.md                 # Full design documentation
└── README.md                            # This file
```

## Customization

### Change Colors

Edit `onboarding_colors.dart`:

```dart
static const Color primaryDeep = Color(0xFF0B5ED7); // Your color
static const Color accentGreen = Color(0xFF16C47F); // Your accent
```

### Modify Screen Content

Edit `onboarding_model.dart`:

```dart
final List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    index: 0,
    title: 'Your Title',
    description: 'Your description',
    emoji: '🎯',
  ),
  // Add more...
];
```

### Adjust Animations

Edit `animated_widgets.dart` - modify durations and curves:

```dart
_animationController = AnimationController(
  duration: const Duration(milliseconds: 1800), // Change duration
  vsync: this,
);

_animation = Tween<double>(begin: 0, end: 1).animate(
  CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut, // Change curve
  ),
);
```

## Dependencies

```yaml
flutter:
  sdk: flutter

# Required for onboarding
flutter_riverpod: ^3.3.1
smooth_page_indicator: ^1.1.0
animations: ^2.0.11
google_fonts: ^8.0.2
lottie: ^2.7.0
```

## Animation Components

### SplashScreen
- **Logo:** Scale 0.7→1.0 with fade, glowing pulse effect
- **Tagline:** Fade in with staggered timing
- **Duration:** 2.5 seconds total, then auto-transitions

### OnboardingScreen
- **Page Transitions:** 500ms smooth scroll with easeInOut
- **Card Entrance:** 800ms scale (0.8→1.0) + fade
- **Chart Animation:** 1800ms bars growing upward
- **Float Effects:** Continuous 3000ms vertical motion

### Key Widgets

| Widget | Purpose | Duration |
|--------|---------|----------|
| `AnimatedChart` | Growing revenue bars | 1800ms |
| `AnimatedFloatingIcon` | Floating icon with glow | 3000ms cycle |
| `PulsingGlowWidget` | Pulsing halo effect | 2000ms cycle |
| `EntranceAnimation` | Scale + fade entrance | 800ms |

## Performance

- **FPS Target:** 60fps (all animations optimized)
- **Memory:** Minimal overhead, proper disposal of controllers
- **Build Size:** ~50KB additional code
- **Startup:** Splash appears immediately, transitions smooth

## Testing

```dart
testWidgets('Onboarding completes successfully', (WidgetTester tester) async {
  await tester.pumpWidget(
    OnboardingFlow(onComplete: () {}),
  );
  
  // Test animation
  await tester.pumpAndSettle();
  expect(find.text('Manage Your Business Easily'), findsOneWidget);
});
```

## Best Practices

1. **Use const constructors** for better performance
2. **Dispose animations** properly in `dispose()`
3. **Test on real devices** for animation smoothness
4. **Consider user preferences** (reduce motion, dark mode)
5. **Keep animations under 2s** for quick flows

## Future Enhancements

- [ ] Lottie-based complex animations
- [ ] Haptic feedback on interactions
- [ ] Dark mode variant
- [ ] Localization support
- [ ] Analytics tracking
- [ ] Skip onboarding locally
- [ ] Personalized screen selection

## Troubleshooting

**Animation lags?**
- Ensure device supports GPU acceleration
- Check for heavy widgets in animation tree
- Profile with Flutter DevTools

**Buttons not tappable?**
- Check GestureDetector wrappers
- Verify state management is working

**Colors look wrong?**
- Verify `onboarding_colors.dart` values
- Check Material theme doesn't override

## Credits

Designed with attention to:
- Material Design 3.0 principles
- Modern SaaS UI patterns (Stripe, Notion)
- African user context and accessibility
- Performance and battery efficiency

## License

Part of MaliUp SaaS platform
