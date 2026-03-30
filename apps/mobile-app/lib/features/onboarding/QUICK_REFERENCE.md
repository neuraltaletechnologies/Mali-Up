# MaliUp Onboarding - Quick Reference & Style Guide

## 🎯 At a Glance

| Aspect | Detail |
|--------|--------|
| **Duration** | 3.5 seconds (splash) + variable (onboarding) |
| **Screens** | 5 total (1 splash + 4 onboarding) |
| **Primary Color** | Deep Blue #0B5ED7 |
| **Accent Color** | Fresh Green #16C47F |
| **Framework** | Flutter (Material 3) |
| **State Management** | Riverpod |
| **Animation Framework** | Flutter built-in + Custom |
| **Target Devices** | Android, iOS, Web |

---

## 🎨 Color Quick Reference

```
┌─ PRIMARY GRADIENT ─────────────────────┐
│ Deep Blue #0B5ED7 → Bright Blue #00A8E8
└────────────────────────────────────────┘

┌─ ACCENT GRADIENT ──────────────────────┐
│ Fresh Green #16C47F → Dark Green #0EA85D
└────────────────────────────────────────┘

┌─ NEUTRALS ─────────────────────────────┐
│ White #FFFFFF     | Dark Gray #1F2937
│ Light Gray #F8FAFC| Medium Gray #6B7280
│ Divider #E5E7EB  | Borders (varies)
└────────────────────────────────────────┘
```

---

## ⚡ Quick Import

```dart
// Everything you need for custom screens:

import 'package:mali_up/features/onboarding/core/onboarding_colors.dart';
import 'package:mali_up/features/onboarding/models/onboarding_model.dart';
import 'package:mali_up/features/onboarding/presentation/widgets/animated_widgets.dart';
import 'package:mali_up/features/onboarding/providers/onboarding_provider.dart';
```

---

## 🎬 Animation Reference

### Common Durations
```
Fast: 300-500ms    (page transitions)
Normal: 800-1200ms (element entrance)
Slow: 1800-3000ms  (complex animation)
```

### Common Curves
```
Entrance: Curves.easeOut
Transition: Curves.easeInOut
Smooth: Curves.decelerate
```

### Pre-built Animations

| Animation | File | Use Case |
|-----------|------|----------|
| `AnimatedChart` | animated_widgets.dart | Show data growth |
| `AnimatedFloatingIcon` | animated_widgets.dart | Hovering elements |
| `PulsingGlowWidget` | animated_widgets.dart | Highlight focus |
| `EntranceAnimation` | animated_widgets.dart | Screen content entry |

---

## 📱 Component Dimensions

### Splash Screen Elements
```
Logo Circle:    120x120px
Logo Size:      60px emoji
Container:      Full screen
Gradient:       Full height
Bottom Accent:  120px height
```

### Onboarding Card Elements
```
Icon Circle:    100x100px
Chart Widget:   280x200px
Button Height:  56px
Card Radius:    24px
Padding:        24px (main), 16px (internal)
```

### Typography Sizes
```
App Name:     48px bold
Titles:       28px bold
Description:  16px regular
Button Text:  16px bold
Labels:       12-13px regular
```

---

## 🔄 State Flow Diagram

```
┌─────────────┐
│   SplashScreen
│  (2.5 seconds)
│     |
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ OnboardingScreen
│   (4 screens)
│     |
│ ┌───┴───┬───────┬────────┐
│ ▼       ▼       ▼        ▼
│ S1:     S2:    S3:      S4:
│ Mgmt    Growth Cloud    CTA
│ |       |      |        |
└─┴───────┴──────┴────┬───┘
                      │
                      ▼
              ┌───────────────┐
              │  onComplete() │
              │  Navigate Out │
              └───────────────┘
```

---

## 🎯 Button Styles

### Primary Button
```dart
Container(
  height: 56,
  decoration: BoxDecoration(
    gradient: LinearGradient([#0B5ED7, #0A4ABC]),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: #0B5ED7.withOpacity(0.25))],
  ),
  child: Text('Button', style: bodyLarge.bold.white),
)
```

### Secondary Button
```dart
Container(
  height: 56,
  decoration: BoxDecoration(
    color: #FFFFFF,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: #0B5ED7.withOpacity(0.3), width: 2),
  ),
  child: Text('Button', style: bodyLarge.bold.primaryDeep),
)
```

---

## 📊 Page Indicator

```
Current: ▰▰▰▰▰▰ (28x8px active)
Inactive: ▪ (8x8px)
Spacing: 6px between indicators
Color: Primary deep blue (#0B5ED7)
```

---

## 🔧 Customization Checklist

### To change colors everywhere:
1. Edit `onboarding_colors.dart`
2. Update gradients in splash_screen.dart if custom
3. Verify card backgrounds in onboarding_screen.dart

### To add/remove screens:
1. Add/remove in `onboarding_model.dart` list
2. Add new condition in `_buildOnboardingPage()`
3. Update button logic in `_buildBottomControls()`

### To modify animations:
1. Find animation in `animated_widgets.dart`
2. Adjust `AnimationController` duration
3. Modify `Tween` begin/end values
4. Change `CurvedAnimation` curve

---

## 🧪 Testing Template

```dart
void main() {
  group('Onboarding Flow Tests', () {
    testWidgets('Splash screen shows and animates', (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp(
        child: SplashScreen(onSplashComplete: () {}),
      ));
      expect(find.text('MaliUp'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Can navigate through all screens', (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp(
        child: OnboardingScreen(onOnboardingComplete: () {}),
      ));
      
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Buttons are properly styled', (WidgetTester tester) async {
      // Verify button dimensions, colors, etc.
    });
  });
}
```

---

## 📦 Dependencies Needed

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_riverpod: ^3.3.1
  
  # Animation & UI
  smooth_page_indicator: ^1.1.0
  animations: ^2.0.11
  
  # Typography
  google_fonts: ^8.0.2
  
  # Advanced animations (optional)
  lottie: ^2.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## 🚀 Performance Tips

| Tip | Benefit |
|-----|---------|
| Use `const` constructors | Reduces rebuilds |
| Separate animation controllers | Cleaner memory management |
| Call `dispose()` properly | Prevents memory leaks |
| Use `SingleWithTickerProviderMixin` | Efficient ticker sharing |
| Profile with DevTools | Find bottlenecks |

---

## 💡 Design Principles

1. **Clarity** - Every element has purpose
2. **Hierarchy** - Important info visible first
3. **Motion** - Animations guide attention
4. **Consistency** - Same patterns throughout
5. **Accessibility** - Works for everyone
6. **Performance** - Smooth 60fps always

---

## 🔗 File Cross-Reference

| Feature | File |
|---------|------|
| Colors | `onboarding_colors.dart` |
| Screens | `splash_screen.dart`, `onboarding_screen.dart` |
| Animations | `animated_widgets.dart` |
| State | `onboarding_provider.dart` |
| Models | `onboarding_model.dart` |
| Flow Control | `onboarding_flow.dart` |
| Docs | `ONBOARDING_DESIGN.md` |
| Integration | `IMPLEMENTATION_GUIDE.dart` |

---

## 🎓 Learning Resources

- Flutter Animations: https://flutter.dev/docs/development/ui/animations
- Material Design 3: https://m3.material.io
- Riverpod: https://riverpod.dev
- smooth_page_indicator: https://pub.dev/packages/smooth_page_indicator

---

## ✅ Launch Checklist

Before shipping onboarding:

- [ ] Test on real Android device
- [ ] Test on real iOS device  
- [ ] Verify animations are smooth (60fps)
- [ ] Test all buttons navigate correctly
- [ ] Check colors match brand guidelines
- [ ] Verify text is readable (all font sizes)
- [ ] Test skip button functionality
- [ ] Verify SharedPreferences persistence
- [ ] Test with "Reduce Motion" enabled
- [ ] Performance test with DevTools
- [ ] Accessibility audit with TalkBack/VoiceOver
- [ ] Analytics tracking working
- [ ] UI matches design mockups

---

## 📞 Quick Troubleshooting

**Q: Animations lag?**
A: Profile with DevTools, reduce animation complexity, check device specs

**Q: Colors look wrong?**
A: Check color profile settings, test on multiple devices

**Q: Buttons don't work?**
A: Verify GestureDetector/InkWell callbacks, check state management

**Q: Won't transition to next screen?**
A: Check onboardingState is updating, verify navigation is set up

**Q: Page indicator stuck?**
A: Ensure PageController is connected to PageView

---

## 🎨 Color Preview

```
PRIMARY DEEP BLUE #0B5ED7
████████████████████

BRIGHT BLUE #00A8E8
████████████████████

FRESH GREEN #16C47F
████████████████████

DARK GREEN #0EA85D
████████████████████

WHITE #FFFFFF
████████████████████

LIGHT GRAY #F8FAFC
████████████████████
```

---

**Version:** 1.0  
**Last Updated:** March 30, 2026  
**Maintainer:** UI/UX Team  
**Status:** Production Ready ✨
