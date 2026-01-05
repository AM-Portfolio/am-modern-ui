import 'package:json_annotation/json_annotation.dart';

/// Derivative types for trade filtering
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DerivativeTypes { futures, options }

/// Extension for DerivativeTypes enum
extension DerivativeTypesExtension on DerivativeTypes {
  String get displayName {
    switch (this) {
      case DerivativeTypes.futures:
        return 'Futures';
      case DerivativeTypes.options:
        return 'Options';
    }
  }
}
