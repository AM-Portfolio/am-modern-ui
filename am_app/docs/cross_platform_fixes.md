# Cross-Platform Fixes Documentation
**Date:** June 4, 2026

This document outlines the exact line-by-line changes made across the `am-modern-ui` workspace to resolve the `JSObject` / `dart:js_interop` compilation errors on Android and iOS. 

## 1. Updated Dependencies

**File:** `am_doc_intelligence_ui/pubspec.yaml`
**Change:**
```diff
  dependencies:
    cupertino_icons: ^1.0.8
+   url_launcher: ^6.3.1
    file_picker: ^8.0.0
```
**Why:** The `url_launcher` package was needed to replace `dart:html` for safely opening web links cross-platform in the `email_extractor_view.dart` file.

---

## 2. Fixed Conditional Imports

In the following files, the conditional import was configured incorrectly. It was previously using `if (dart.library.io)` to switch to the stub, meaning the `dart:html` web version was the default. The Dart compiler analyzes the default file for mobile targets, which caused the build crash.

### A. Optional Fields Section
**File:** `am_trade_ui/lib/features/trade/presentation/web/widgets/journal/sections/optional_fields_section.dart`
**Change:** (Lines 4)
```diff
- import '../widgets/url_preview_widget.dart' if (dart.library.io) '../widgets/url_preview_widget_stub.dart';
+ import '../widgets/url_preview_widget_stub.dart' if (dart.library.html) '../widgets/url_preview_widget.dart';
```
**Why:** Reverses the logic so the stub is the default, and the web file is only compiled for the web.

### B. Attachment Picker
**File:** `am_common/lib/features/attachment/internal/presentation/widgets/attachment_picker/attachment_picker.dart`
**Change:** (Lines 7-8)
```diff
- import 'web/attachment_picker_web.dart'
-    if (dart.library.io) 'web/attachment_picker_web_stub.dart'
+ import 'web/attachment_picker_web_stub.dart'
+    if (dart.library.html) 'web/attachment_picker_web.dart'
```
**Why:** Reverses the logic to protect the mobile build path from analyzing `attachment_picker_web.dart`.

### C. Google Sign-In Service
**File:** `am_auth_ui/lib/features/authentication/data/services/google_signin_service.dart`
**Change:** (Line 2)
```diff
- export 'google_signin_service_web.dart' if (dart.library.io) 'google_signin_service_stub.dart';
+ export 'google_signin_service_stub.dart' if (dart.library.html) 'google_signin_service_web.dart';
```
**Why:** Protects mobile platforms from analyzing `google_signin_service_web.dart`.

---

## 3. Removed Direct `dart:html` Usage

### Email Extractor View
**File:** `am_doc_intelligence_ui/lib/features/email_extractor/email_extractor_view.dart`
**Change:** (Lines 2-4)
```diff
- // ignore: avoid_web_libraries_in_flutter
- import 'dart:html' as html;
+ import 'package:url_launcher/url_launcher.dart';
```
**Change:** (Lines 116-117)
```diff
          final String authUrl = result['auth_url'];
          // Open OAuth in new tab
-         html.window.open(authUrl, '_blank');
+         launchUrl(Uri.parse(authUrl));
```
**Why:** Direct usage of `dart:html` makes a file impossible to compile on Android. `url_launcher` does the exact same thing (opens a URL in a new tab) but works flawlessly across Web, Android, iOS, and Desktop.

---

## 4. Refactored File Downloader

The original `file_downloader.dart` directly imported `dart:html` to process a file blob and trigger a browser download. Because this file is imported by the main app, it broke Android compilation.

**Old File Removed:** `am_doc_intelligence_ui/lib/utils/file_downloader.dart` (Contents deleted).

**New Files Created:**

1. **`am_doc_intelligence_ui/lib/utils/file_downloader_web.dart`**
   - **Contents:** The exact old logic from `file_downloader.dart` using `html.AnchorElement`.
   - **Why:** Safely isolates the web-only download logic so it is only compiled when building for the web.

2. **`am_doc_intelligence_ui/lib/utils/file_downloader_stub.dart`**
   - **Contents:** An empty stub `FileDownloader` class.
   - **Why:** Provides the `FileDownloader` class to the Android/iOS compilation path so the app still compiles, even though web-downloads aren't supported on mobile yet.

3. **`am_doc_intelligence_ui/lib/utils/file_downloader.dart`**
   - **New Contents:** 
     ```dart
     export 'file_downloader_stub.dart' if (dart.library.html) 'file_downloader_web.dart';
     ```
   - **Why:** Acts as the cross-platform router. The app imports `file_downloader.dart`, and the Dart compiler automatically picks the `stub` for Android/iOS, and the `web` version for Web.

---

## 5. Removed `webview_flutter_web` Direct Dependency

**File:** `am_app/pubspec.yaml`
**Change:** (Line 61)
```diff
  webview_flutter: ^4.9.0
- webview_flutter_web: ^0.2.3+4
```
**Why:** `webview_flutter_web` is a web-platform-specific package that depends on `package:web` 1.1.1, which internally uses `dart:js_interop`. When listed as a **direct main dependency**, the Dart compiler analyzes it for ALL platforms including Android, causing hundreds of `JSObject` errors. This package is NOT needed as a direct dependency because `webview_flutter` already auto-includes the correct web implementation through Flutter's federated plugin system. Removing this line stops `package:web` 1.1.1 from being pulled into the Android compilation path.
