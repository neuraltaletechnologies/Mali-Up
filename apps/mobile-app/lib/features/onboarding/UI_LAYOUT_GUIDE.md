# MaliUp Onboarding - UI Layout & Wireframes

## 📐 Screen Layout Overview

### Screen 0: Splash Screen
```
┌─────────────────────────────────┐
│                                 │
│  ▲▲▲ Gradient Background        │
│  ▲▲▲ (Blue to Green)            │
│                                 │
│        ╭─────────────╮          │
│        │     📱      │          │
│        │  (Logo)     │          │ ✨ Pulsing glow
│        ╰─────────────╯          │
│                                 │
│      M A L I X                  │
│                                 │
│   Smart Business Management     │
│     for Growing Businesses      │
│                                 │
└─────────────────────────────────┘
```

**Timing:** 2.5 seconds → Auto-transitions to Screen 1

---

### Screen 1: Manage Your Business Easily
```
┌─────────────────────────────────┐
│  ■  ◆◆◆◆◆ ◆◆◆◆◆ ○  (indicator)  │
│                                 │
│        ╭─────────────╮          │
│        │     📊      │          │
│        │  Dashboard  │          │
│        ╰─────────────╯          │
│                                 │
│   ┌─────────────────────────┐   │
│   │  12,500   │   345       │   │
│   │  Sales    │   Clients   │   │ (Stats cards)
│   ├─────────────────────────┤   │
│   │  28       │   92+       │   │
│   │  Products │   Orders    │   │
│   └─────────────────────────┘   │
│                                 │
│  Manage Your Business Easily    │
│                                 │
│  Track sales, customers, and    │
│  daily operations in one place  │
│                                 │
│         [  Continue  ]          │ (Primary button)
└─────────────────────────────────┘
```

---

### Screen 2: Track Money & Growth
```
┌─────────────────────────────────┐
│  ■  ◆◆◆◆◆ ◆◆◆◆◆◆ ○              │
│                                 │
│        ╭─────────────╮          │
│        │     📈      │          │
│        │   Growth    │          │
│        ╰─────────────╯          │
│                                 │
│   ┌─────────────────────────┐   │
│   │ Monthly Revenue    +23% │   │
│   ├─────────────────────────┤   │
│   │ █  █ █  █ █           │   │
│   │ █  █ █  █ █           │   │ (Growing bars)
│   │ █  █ █  █ █           │   │
│   └─────────────────────────┘   │
│                                 │
│  Track Money & Growth           │
│                                 │
│  Monitor income, expenses, and  │
│  profits in real time           │
│                                 │
│         [  Continue  ]          │
└─────────────────────────────────┘
```

---

### Screen 3: Control Everything Anywhere
```
┌─────────────────────────────────┐
│  ■  ◆◆◆◆◆ ◆◆◆◆◆◆ ◆              │
│                                 │
│        ╭─────────────╮          │
│        │     ☁️      │          │
│        │  Cloud Sync │          │
│        ╰─────────────╯          │
│                                 │
│         ╭──────────╮            │
│         │ ☁️ Sync  │            │ (Floating)
│         ╰──────────╯            │
│                                 │
│        ╭────────────╮           │
│        │  📱 ✓      │           │ (Mobile with check)
│        ╰────────────╯           │
│                                 │
│  Control Everything Anywhere    │
│                                 │
│  Access your business anytime,  │
│  anywhere from your mobile      │
│                                 │
│         [  Continue  ]          │
└─────────────────────────────────┘
```

---

### Screen 4: Ready to Launch (CTA)
```
┌─────────────────────────────────┐
│  ■  ◆◆◆◆◆ ◆◆◆◆◆◆ ◆◆              │
│                                 │
│        ╭─────────────╮          │
│        │     🚀      │          │
│        │   Launch    │          │
│        ╰─────────────╯          │
│                                 │
│   ┌─────────────────────────┐   │
│   │       🚀 Ready?         │   │
│   │ Take control of your    │   │
│   │ business                │   │
│   └─────────────────────────┘   │
│                                 │
│  Get Started with MaliUp         │
│                                 │
│  Join thousands of African      │
│  business owners managing...    │
│                                 │
│   [Register Business]           │ (Primary)
│                                 │
│  Already have account? [Login]  │ (Secondary)
└─────────────────────────────────┘
```

---

## 🎨 Component Specifications

### Page Indicator
```
Active:   ▰▰▰▰▰▰ (Blue, 28x8px)
Inactive: ▪ (Gray, 8x8px)
Spacing:  6px
Position: Top center, below app bar
```

### Icon/Emoji Circle
```
Shape:      Perfect circle
Size:       100x100px
Background: Gradient (blue or green based on screen)
Emoji Size: ~50-60px
Content:    📊 📈 ☁️ 🚀 (varies by screen)
Animation:  Floating or pulsing
```

### Stat Card
```
Height:     Variable (fit content)
Background: White with border
Padding:    8px internal
Border:     1px solid (color-based)
Border Radius: 12px
Layout:     Vertical (value on top, label below)

Value:      Font Bold, Small (18-20px)
Label:      Font Regular, Tiny (11-12px), Gray color
```

### Chart Widget
```
Size:       280x200px
Background: Gradient (light blue)
Border:     1.5px solid light blue
Radius:     24px
Padding:    16px

Header:
  - Label on left
  - Badge on right (+23%)

Content:
  - 5 animated bars
  - Equal spacing
  - Green gradient (top to darker)
  - Heights vary: 40%, 60%, 50%, 80%, 70%
```

### Buttons
```
Primary Button:
  - Width: Full width (with padding)
  - Height: 56px
  - Background: Blue gradient (#0B5ED7 → #0A4ABC)
  - Text: White, Bold, 16px
  - Radius: 16px
  - Shadow: Blue shadow (0.25 opacity)
  - Animation: Scale on press

Secondary Button:
  - Width: Full width
  - Height: 56px
  - Background: White
  - Border: 2px Blue (0.3 opacity)
  - Text: Blue, Bold, 16px
  - Radius: 16px
  - No shadow
  - Animation: Opacity change on press
```

---

## 📐 Spacing Metrics

### Vertical Spacing
```
Top Padding (safe area):    16-24px
Icon to content:            40px
Content to description:     12px
Description to button:      40-50px
Bottom Padding:             24px
```

### Horizontal Spacing
```
Screen edges:               24px padding
Card to screen:             24px margin
Element to element:         12-16px gap
Content horizontal:         24px max-width center
```

---

## 🌊 Background Patterns

### Splash Screen
```
Gradient: Top-Left (Blue) to Bottom-Right (Green)
Overlays: 
  - Top-right circle: Light Green (opacity 15%)
  - Bottom-left circle: White (opacity 8%)
  - Bottom gradient fade: Dark overlay
```

### Onboarding Screens
```
Background: Solid light gray (#F8FAFC)
Card boxes:
  - Screen 1: Light Blue gradient
  - Screen 2: Light Blue gradient with chart
  - Screen 3: Light Green gradient
  - Screen 4: Light Blue gradient
```

---

## 🔤 Typography Grid

### Headlines
```
Screen Title:     28px Bold, Dark Gray (#1F2937)
App Name:         48px Bold, White (splash only)
Card Label:       13px Regular, Dark Gray
```

### Body Text
```
Description:      16px Regular, Medium Gray (#6B7280)
Tagline:          16px Regular, White (splash only)
Button:           16px Bold, White/Blue (context)
Small Labels:     12px Regular, Light Gray
```

### Font Family
All text uses: **Outfit** (via Google Fonts)

---

## 🎭 Animation Timeline

### Splash Screen Timeline
```
0ms       400ms       1000ms      2500ms
│─────────│───────────│───────────│──────────→ 3500ms
Logo ████
Tagline       ████████████████████
Pulsing ◆◆◆◆◆◆◆(continuous until transition)
```

### Page Transition Timeline
```
Page visible: [Current Page showing ←→ Next Page entering]
Duration:     500ms easeInOut
```

### Card Entrance Timeline
```
0ms         600ms
│───────────│─────────→ 800ms
Scale ████████
Fade  ████████
```

---

## 🎬 Animation Details

### Splash Logo
```
Start:  Scale 0.7, Opacity 0
End:    Scale 1.0, Opacity 1
Time:   0-600ms
Curve:  easeOut
Effect: "Zoom in with fade"
```

### Page Transitions
```
Start:  Previous full visible
End:    New page full visible
Time:   500ms
Curve:  easeInOut
Effect: "Smooth horizontal scroll"
```

### Chart Bars
```
Start:  Height 0
End:    Target height (40-80%)
Times:  Staggered (each 100ms)
Curve:  easeOut
Effect: "Growing bars with visual growth"
```

---

## ✨ Visual Hierarchy

### Screen 1 (Dashboard)
1. Icon (attention)
2. Stats cards (key info)
3. Title (context)
4. Description (details)
5. Button (action)

### Screen 2 (Analytics)
1. Icon (attention)
2. Chart (key data)
3. Title (context)
4. Description (details)
5. Button (action)

### Screen 3 (Cloud)
1. Icon (attention)
2. Sync illustration (key feature)
3. Title (context)
4. Description (details)
5. Button (action)

### Screen 4 (CTA)
1. Icon (attention)
2. Illustration (context)
3. Title (strong)
4. Description (benefit)
5. Primary Button (main action)
6. Secondary Button (alternative)

---

## 🎨 Color Usage Guide

### By Screen
```
Screen 1: Blue theme (dashboard)
Screen 2: Blue theme with green accents (growth)
Screen 3: Green theme (sync/positive)
Screen 4: Blue theme (call to action)
```

### By Element
```
Primary Action:   Blue gradient
Secondary Action: Blue border + text
Success:          Green
Text:             Dark gray
Backgrounds:      Light gray or white
Cards:            White with color borders
Accents:          Green highlights
```

---

## 📴 Safe Area Considerations

```
Top:    Status bar + 8px
Bottom: Home indicator + 8px + buttons
Sides:  8px margin on both sides
```

---

## 📱 Multi-Device Scaling

| Device | Scaling | Notes |
|--------|---------|-------|
| Small (320px) | 0.9x | Adjust padding |
| Medium (375px) | 1x | Default |
| Large (414px) | 1x | Same as medium |
| XLarge (480px+) | 1.1x | Increase spacing |

---

## 🚀 Implementation Checklist

- [ ] All screens match layouts above
- [ ] Colors match specifications exactly
- [ ] Spacing matches 12px grid
- [ ] Typography matches sizes and weights
- [ ] Buttons respond to touches
- [ ] Animations follow timings
- [ ] Page indicator updates correctly
- [ ] Icons/emojis render clearly
- [ ] Text is readable on all devices
- [ ] Cards have proper shadows
- [ ] Gradients blend smoothly

---

**Document Version:** 1.0  
**Last Updated:** March 30, 2026
