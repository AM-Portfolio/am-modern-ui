import 'package:json_annotation/json_annotation.dart';

/// Index types for trade filtering
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum IndexTypes { nifty, banknifty, finnifty, midcpnifty }

/// Extension for IndexTypes enum
extension IndexTypesExtension on IndexTypes {
  String get displayName {
    switch (this) {
      case IndexTypes.nifty:
        return 'NIFTY';
      case IndexTypes.banknifty:
        return 'BANKNIFTY';
      case IndexTypes.finnifty:
        return 'FINNIFTY';
      case IndexTypes.midcpnifty:
        return 'MIDCPNIFTY';
    }
  }
}
