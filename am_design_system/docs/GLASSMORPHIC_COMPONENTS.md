# Glassmorphic UI Component Library

A modern, animated UI component library with glassmorphic design, vibrant gradients, and smooth animations inspired by premium interfaces.

![Reference Image](../../../../../.gemini/antigravity/brain/a1edca73-21ac-43ac-8327-35f8c24d04e3/uploaded_image_1767304004677.png)

## Features

- 🎨 **Glassmorphic Design** - Frosted glass effects with beautiful borders and shadows
- ✨ **Smooth Animations** - Hover effects, transitions, and micro-interactions
- 🌈 **Vibrant Gradients** - Multi-color gradients and glossy finishes
- 📦 **Ready-to-Use Components** - Cards, buttons, sidebars, and more
- 🎯 **Reusable Templates** - Secondary sidebar for all modules

## Components

### 1. Cards

#### GlassCard
Glassmorphic card with frosted glass effect, borders, and shadows.

```dart
GlassCard(
  child: Text('Content'),
  borderColor: AppColors.primary,
  borderWidth: 1.0,
  blur: 10.0,
  onTap: () {},
)
```

#### MetricCard
Metric display card (like in the reference image) with icon, label, and value.

```dart
MetricCard(
  label: 'Symbols Processed',
  value: '1',
  icon: Icons.trending_up,
  accentColor: AppColors.info,
  onTap: () {},
)
```

**Features:**
- Animated hover effects
- Colored icon badge
- Beautiful shadows with accent color
- Optional trailing widget

#### GradientCard
Card with vibrant gradient backgrounds.

```dart
GradientCard(
  gradientColors: [
    AppColors.primary,
    AppColors.primaryLight,
  ],
  child: Text('Content'),
  onTap: () {},
)
```

### 2. Buttons

#### GlossyButton
Glossy gradient button with glow effects.

```dart
GlossyButton(
  text: 'Click Me',
  onPressed: () {},
  icon: Icons.star,
  gradientColors: [AppColors.primary, AppColors.primaryLight],
  isLoading: false,
)
```

**Features:**
- Gradient backgrounds
- Animated glow on hover
- Scale animation
- Loading state
- Optional icon

#### GlassButton
Frosted glass button with subtle borders.

```dart
GlassButton(
  text: 'Glass Style',
  onPressed: () {},
  icon: Icons.layers,
  borderColor: AppColors.primary,
)
```

#### GlowIconButton
Icon button with glow effect on hover.

```dart
GlowIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  color: AppColors.accentPink,
  size: 24.0,
)
```

### 3. Layouts

#### SecondarySidebar
Reusable glassmorphic sidebar template for all modules.

```dart
SecondarySidebar(
  title: 'Menu',
  width: 280,
  items: [
    SecondarySidebarItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      onTap: () {},
      accentColor: AppColors.primary,
      trailing: Badge(label: Text('5')),
    ),
    SecondarySidebarItem(
      title: 'Analytics',
      icon: Icons.bar_chart,
      onTap: () {},
      accentColor: AppColors.accent,
    ),
  ],
  header: CustomHeader(),
  footer: CustomFooter(),
  showDividers: true,
)
```

**Features:**
- Glassmorphic background
- Animated hover effects on items
- Colored icon badges with glow
- Optional header/footer
- Configurable dividers

#### SecondarySidebarSection
Collapsible section within sidebar.

```dart
SecondarySidebarSection(
  title: 'Analytics',
  icon: Icons.bar_chart,
  accentColor: AppColors.primary,
  initiallyExpanded: true,
  items: [...],
)
```

## Design System

### Theme

The glassmorphic styles are defined in `app_glassmorphism.dart`:

```dart
// Glass card decoration
AppGlassmorphism.glassCard(
  borderColor: Colors.white.withOpacity(0.1),
  borderWidth: 1.0,
  blur: 10.0,
)

// Metric card decoration
AppGlassmorphism.metricCard(
  accentColor: AppColors.primary,
  elevation: 8.0,
)

// Glossy button decoration
AppGlassmorphism.glossyButton(
  gradientColors: [AppColors.primary, AppColors.primaryLight],
  borderRadius: 12.0,
)

// Sidebar glass effect
AppGlassmorphism.sidebarGlass(
  borderWidth: 1.0,
)
```

### Colors

Vibrant color palette with gradients (defined in `app_colors.dart`):

```dart
// Primary colors
AppColors.primary
AppColors.primaryLight
AppColors.primaryDark

// Accent colors
AppColors.accent
AppColors.accentBlue
AppColors.accentPink

// Status colors
AppColors.success
AppColors.error
AppColors.warning
AppColors.info

// Multi-color palette
AppColors.multiColors
AppColors.getMultiColor(index)

// Gradients
AppColors.primaryGradient
AppColors.glassGradient
```

## Usage Example

See `examples/glassmorphic_showcase.dart` for a complete showcase of all components.

```dart
import 'package:am_common_ui/am_common_ui.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Row(
        children: [
          // Secondary Sidebar
          SecondarySidebar(
            title: 'Dashboard',
            items: [...],
          ),
          
          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  // Metric Cards Grid
                  GridView(
                    children: [
                      MetricCard(
                        label: 'Revenue',
                        value: '₹2.4M',
                        icon: Icons.attach_money,
                        accentColor: AppColors.success,
                      ),
                      // More metric cards...
                    ],
                  ),
                  
                  // Glass Card
                  GlassCard(
                    child: YourContent(),
                  ),
                  
                  // Glossy Button
                  GlossyButton(
                    text: 'Save',
                    icon: Icons.save,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Use Dark Backgrounds**: Glassmorphic effects work best on dark backgrounds
2. **Accent Colors**: Use different accent colors for different metric cards
3. **Hover Effects**: All interactive components have built-in hover animations
4. **Consistency**: Use the same design patterns across all modules
5. **Performance**: Components use `AnimationController` for smooth 60fps animations

## Integration

Add to your module's `pubspec.yaml`:

```yaml
dependencies:
  am_common_ui:
    path: ../am_common_ui
```

Import in your Dart files:

```dart
import 'package:am_common_ui/am_common_ui.dart';
```

## Components Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart
│       ├── app_glassmorphism.dart
│       ├── app_theme.dart
│       └── app_typography.dart
├── widgets/
│   ├── buttons/
│   │   └── glossy_button.dart
│   ├── display/
│   │   └── glass_card.dart
│   └── layouts/
│       └── secondary_sidebar.dart
└── examples/
    └── glassmorphic_showcase.dart
```

## Customization

All components support extensive customization through parameters:

- **Colors**: Border colors, accent colors, gradient colors
- **Sizing**: Width, height, padding, border radius
- **Effects**: Blur amount, shadow elevation, glow intensity
- **Behavior**: onTap, onPressed, loading states

---

**Created with ✨ by the AM Investment Team**
