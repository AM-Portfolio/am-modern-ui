# Design tokens (AM)

## What are tokens?

Named design values in one place. Screens and kit components use the **name**, not magic numbers.

| Family | API | Example |
|--------|-----|---------|
| Type scale | `AppTypeScale` | `h3 = 22` |
| Text roles | `AppTextStyles` / `context.text` | `context.text.pageTitle(compact: true)` |
| Space | `AppSpacing` | `AppSpacing.md` |
| Radii | `AppRadii` | `AppRadii.lg` |
| Component sizes | `AppComponentSizes` | `buttonHeight`, `inputHeight` |
| Color | `context.colors` | `textPrimary`, `actionPrimaryBg` |
| Brand | `BrandConfig` via `DesignSystemProvider` | `context.brand.appName`, logo, primary |

Flow: **tokens → kit components → screens**.

## Do

```dart
Text(
  'Create account',
  style: context.text.pageTitle(compact: isCompact)
      .copyWith(color: context.colors.textPrimary),
);
```

## Don't

- `TextStyle(fontSize: 18)` in feature packages
- `Color(0xFF…)` / `Colors.purple` for product chrome
- New parallel cards/fields/buttons — extend the kit

## White-label

Wrap the app with `DesignSystemProvider(config: BrandConfig(...))`. Auth reads `context.brand` for name/logo/primary.
