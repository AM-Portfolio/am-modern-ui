# Glassmorphic UI Components - Quick Start Guide

## ⚡ Quick Integration (3 Steps)

### Step 1: Import the Library

```dart
import 'package:am_common_ui/am_common_ui.dart';
```

### Step 2: Use Components

```dart
class MyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Row(
        children: [
          // ✨ Add Secondary Sidebar
          SecondarySidebar(
            title: 'Dashboard',
            items: [
              SecondarySidebarItem(
                title: 'Overview',
                icon: Icons.dashboard,
                onTap: () => print('Overview tapped'),
                accentColor: AppColors.primary,
              ),
            ],
          ),
          
          // Main Content Area
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: GridView.count(
                crossAxisCount: 3,
                children: [
                  // ✨ Add Metric Cards (like your reference image)
                  MetricCard(
                    label: 'Total Revenue',
                    value: '₹2.4M',
                    icon: Icons.attach_money,
                    accentColor: AppColors.success,
                  ),
                  MetricCard(
                    label: 'Active Users',
                    value: '1,234',
                    icon: Icons.people,
                    accentColor: AppColors.info,
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

### Step 3: Run!

```bash
flutter run
```

## 🎨 Component Cheat Sheet

### Metric Card (From Your Reference)
```dart
MetricCard(
  label: 'Symbols Processed',
  value: '1',
  icon: Icons.trending_up,
  accentColor: AppColors.info,  // Blue glow
)
```

### Glass Card
```dart
GlassCard(
  child: YourContent(),
  borderColor: AppColors.primary,
)
```

### Glossy Button
```dart
GlossyButton(
  text: 'Save Changes',
  icon: Icons.save,
  onPressed: () {},
  gradientColors: [AppColors.primary, AppColors.primaryLight],
)
```

### Secondary Sidebar
```dart
SecondarySidebar(
  title: 'Menu',
  items: [
    SecondarySidebarItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      onTap: () {},
      accentColor: AppColors.primary,
    ),
  ],
)
```

## 🎯 Common Use Cases

### Dashboard with Metrics Grid
```dart
GridView.count(
  crossAxisCount: 3,
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
  children: [
    MetricCard(label: 'Revenue', value: '₹2.4M', icon: Icons.money, accentColor: AppColors.success),
    MetricCard(label: 'Users', value: '1,234', icon: Icons.people, accentColor: AppColors.info),
    MetricCard(label: 'Orders', value: '567', icon: Icons.shopping_cart, accentColor: AppColors.accent),
  ],
)
```

### Content Card with Action Button
```dart
Column(
  children: [
    GlassCard(
      child: Column(
        children: [
          Text('Your Content'),
          SizedBox(height: 16),
          GlossyButton(
            text: 'Action',
            onPressed: () {},
          ),
        ],
      ),
    ),
  ],
)
```

### Sidebar with Sections
```dart
SecondarySidebar(
  title: 'Navigation',
  items: [
    SecondarySidebarSection(
      title: 'Analytics',
      icon: Icons.bar_chart,
      items: [
        SecondarySidebarItem(title: 'Overview', icon: Icons.dashboard, onTap: () {}),
        SecondarySidebarItem(title: 'Reports', icon: Icons.file_copy, onTap: () {}),
      ],
    ),
  ],
)
```

## 🌈 Color Accent Guide

Use different accent colors for different types of metrics:

- **Blue** (`AppColors.info`) - General metrics, data
- **Green** (`AppColors.success`) - Revenue, positive metrics
- **Orange** (`AppColors.accent`) - Activity, engagement
- **Red** (`AppColors.error`) - Failed, errors
- **Purple** (`AppColors.primary`) - Primary actions
- **Cyan** (`AppColors.accentBlue`) - Tech metrics
- **Pink** (`AppColors.accentPink`) - Social metrics

## 🔧 Run the Showcase

To see all components in action:

```bash
cd am_common_ui
flutter run -d chrome
```

Then navigate to `GlassmorphicShowcase()` in your app.

## 📚 Full Documentation

See [GLASSMORPHIC_COMPONENTS.md](GLASSMORPHIC_COMPONENTS.md) for complete API documentation.

---

**Need Help?** Check the examples folder or contact the AM team.
