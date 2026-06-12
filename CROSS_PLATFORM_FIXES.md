# Cross-Platform Compilation Fixes

This document outlines the recent changes made to the codebase to resolve compilation errors (`JSObject` and `dart:js_interop` is not available) when building the app for non-web platforms (Android, iOS, Windows, etc.).

## The Problem
The Flutter Dart compiler requires that web-specific libraries like `dart:html` and `package:web` are strictly isolated from the main execution path when building for mobile or desktop targets. If any file imported into the widget tree directly imports these libraries—or if conditional imports are configured incorrectly—the compiler will fail.

## Changes Made

### 1. Fixed Conditional Imports
In several files, the conditional import was configured to import the web file by default and only fallback to the stub for `dart.library.io`. This was incorrect, as it forced the compiler to analyze the web file for the default cross-platform target.
We swapped the condition to use the stub by default, and only import the web version if `dart.library.html` is present.

* **Files Modified:**
  * `am_trade_ui/lib/features/trade/presentation/web/widgets/journal/sections/optional_fields_section.dart`
  * `am_common/lib/features/attachment/internal/presentation/widgets/attachment_picker/attachment_picker.dart`
  * `am_auth_ui/lib/features/authentication/data/services/google_signin_service.dart`

### 2. Removed Direct `dart:html` from Email Extractor
The `email_extractor_view.dart` file directly imported `dart:html` to open an OAuth URL in a new browser tab.
* **Fix:** Replaced `dart:html` with the cross-platform `url_launcher` package. `launchUrl(Uri.parse(authUrl))` automatically opens new tabs safely on Web while compiling perfectly on Mobile.
* **Dependencies:** Added `url_launcher: ^6.3.1` to `am_doc_intelligence_ui/pubspec.yaml`.

### 3. Refactored File Downloader
The `file_downloader.dart` directly used `html.AnchorElement` and `html.Blob` to trigger file downloads.
* **Fix:** Split the implementation into three files:
  1. `file_downloader_web.dart`: Contains the original web-specific logic.
  2. `file_downloader_stub.dart`: Contains an empty mobile stub.
  3. `file_downloader.dart`: Now acts as a pure export wrapper `export 'file_downloader_stub.dart' if (dart.library.html) 'file_downloader_web.dart';`.

## How to Review
These changes are purely structural to satisfy the Dart compiler. They do **not** change any actual logic or behavior on the web. The web version will behave identically because `dart.library.html` remains true in Chrome/Edge, routing execution to the exact same web files as before.
