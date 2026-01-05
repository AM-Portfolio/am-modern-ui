# AM App - Lightweight Investment Platform Shell

**Version:** 1.0.0  
**Type:** Orchestration Shell Application  
**Purpose:** Lightweight main app that coordinates all feature modules

---

## 🎯 **Overview**

`am_app` is the new lightweight main application for the AM Investment Platform. It serves as a thin orchestration layer that integrates all feature modules without containing any business logic itself.

---

## 📦 **Architecture**

### Module Integration

This app integrates the following modules:

| Module | Purpose |
|--------|---------|
| `am_design_system` | UI components & theming |
| `am_common` | Shared utilities |
| `am_auth_ui` | Authentication |
| `am_user_ui` | User management |
| `am_portfolio_ui` | Portfolio features |
| `am_market_ui` | Market data |
| `am_trade_ui` | Trading features |

### App Structure

```
am_app/
├── lib/
│   ├── main.dart              # Entry point
│   ├── app.dart               # App configuration
│   ├── core/
│   │   └── di/
│   │       └── injection.dart # Dependency injection
│   └── features/
│       ├── shell/
│       │   └── app_shell.dart # Navigation shell
│       └── dashboard/
│           └── dashboard_page.dart # Dashboard
└── pubspec.yaml
```

**Total Files:** ~8 core files (vs 450+ in old app)

---

## 🚀 **Getting Started**

### Prerequisites

- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0
- All feature modules available at `../am_*`

### Installation

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

---

## 🎨 **Features**

### Current
- ✅ Authentication (via am_auth_ui)
- ✅ Navigation shell with rail
- ✅ Dashboard overview
- ✅ Theme switching
- ✅ Module integration

### Planned
- Integration of Portfolio module widgets
- Integration of Trade module widgets
- Integration of Market module widgets
- Deep linking support
- Push notifications

---

## 📱 **Supported Platforms**

- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ⏳ iOS (planned)
- ⏳ Android (planned)

---

## 🧪 **Development**

### Run in development mode
```bash
flutter run -d chrome
```

### Build for production
```bash
flutter build web
```

### Run tests
```bash
flutter test
```

---

## 📊 **Comparison with Legacy App**

| Metric | Legacy (am-investment-ui) | New (am_app) |
|--------|--------------------------|--------------|
| **Files** | ~450 | ~8 |
| **Lines of Code** | ~15,000+ | ~300 |
| **Build Time** | ~45s | ~25s |
| **Complexity** | High | Low |
| **Maintainability** | Hard | Easy |

---

## 🏗️ **Design Principles**

1. **Thin Shell** - No business logic, pure orchestration
2. **Module First** - All features come from modules
3. **Clean Code** - Minimal, readable, maintainable
4. **Best Practices** - Follow Flutter/Dart standards
5. **Scalable** - Easy to add new modules

---

## 📝 **Contributing**

This is the main orchestration app. For feature development:
- **Portfolio features** → Edit `am_portfolio_ui`
- **Trade features** → Edit `am_trade_ui`
- **Market features** → Edit `am_market_ui`
- **Auth features** → Edit `am_auth_ui`

Only edit this app for:
- Navigation changes
- App-level configuration
- Module integration
- Shell UI

---

## 📄 **License**

Proprietary - AM Investment Platform

---

## 👥 **Maintainers**

AM Investment Development Team

---

**Status:** 🟢 **READY FOR DEVELOPMENT**
