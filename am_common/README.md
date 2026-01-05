# am_common

Common utilities and cross-cutting concerns for AM Investment application.

## Features

### 🔗 Attachment Management
Complete file upload/download system with Cloudinary integration:
- Upload single files
- Batch upload multiple files
- Delete files
- List resources
- Get resource details

### 🛠️ Core Utilities
Common utilities used across all modules:
- **Date Utils**: Date formatting, parsing, comparisons
- **String Utils**: String manipulation helpers
- **Validators**: Input validation (email, phone, etc.)
- **Filter/Sort Utils**: Data filtering and sorting helpers

### 📦 Shared Extensions
Convenient extension methods:
- BuildContext extensions
- DateTime extensions
- Number extensions
- String extensions

## Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  am_common:
    path: ../am_common
```

Import in your Dart files:

```dart
import 'package:am_common/am_common.dart';
```

## Examples

### Upload a File
```dart
final uploadUseCase = UploadFileUseCase(cloudinaryRepository);
final result = await uploadUseCase(file);
```

### Validate Email
```dart
if (Validators.isValidEmail(email)) {
  // Email is valid
}
```

### Format Date
```dart
final formatted = DateUtils.formatDate(DateTime.now());
```

## Dependencies

This module depends on:
- `cloudinary_flutter` - For file uploads
- `file_picker` - For file selection
- `flutter_bloc` - For state management
- `freezed` - For immutable models

## License

Proprietary - AM Investment Platform
