import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Local broker logo assets under `assets/images/brokers/`.
const String _pkg = 'am_doc_intelligence_ui';

/// Normalize email-extractor ids and doc-processor codes to a logo key.
String? _logoKey(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  switch (raw.toLowerCase().replaceAll('-', '_')) {
    case 'zerodha':
      return 'zerodha';
    case 'groww':
      return 'groww';
    case 'angleone':
    case 'angelone':
    case 'angel_one':
      return 'angelone';
    case 'dhan':
      return 'dhan';
    case 'mstock':
      return 'mstock';
    default:
      return null;
  }
}

/// Asset path for a known broker id/code, or null.
String? brokerLogoAsset(String? brokerId) {
  switch (_logoKey(brokerId)) {
    case 'zerodha':
      return 'assets/images/brokers/zerodha.png';
    case 'groww':
      return 'assets/images/brokers/groww.png';
    case 'angelone':
      return 'assets/images/brokers/angelone.png';
    case 'dhan':
      return 'assets/images/brokers/dhan.png';
    case 'mstock':
      return 'assets/images/brokers/mstock.png';
    default:
      return null;
  }
}

/// Short label for dropdowns / tiles (doc codes or email-extractor ids).
String brokerDisplayName(String code) {
  switch (code.toLowerCase().replaceAll('-', '_')) {
    case 'zerodha':
      return 'Zerodha';
    case 'groww':
      return 'Groww';
    case 'angel_one':
    case 'angelone':
    case 'angleone':
      return 'Angel One';
    case 'dhan':
      return 'Dhan';
    case 'mstock':
      return 'mStock';
    case 'upstox':
      return 'Upstox';
    case '__auto__':
      return 'Auto-detect';
    default:
      final upper = code.toUpperCase();
      switch (upper) {
        case 'ZERODHA':
          return 'Zerodha';
        case 'GROWW':
          return 'Groww';
        case 'ANGEL_ONE':
          return 'Angel One';
        case 'DHAN':
          return 'Dhan';
        case 'MSTOCK':
          return 'mStock';
        case 'UPSTOX':
          return 'Upstox';
        case '__AUTO__':
          return 'Auto-detect';
        default:
          return code;
      }
  }
}

/// Colored letter chip when no logo asset exists (e.g. Upstox).
Widget brokerLetterAvatar(String code, {double size = 26}) {
  final name = brokerDisplayName(code);
  final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: ModuleColors.analytics.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(size * 0.22),
    ),
    child: Text(
      letter,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: size * 0.45,
        color: ModuleColors.analytics,
      ),
    ),
  );
}

/// Ordered logos for the Equity Portfolios capabilities row.
const List<String> equityBrokerLogoAssets = [
  'assets/images/brokers/zerodha.png',
  'assets/images/brokers/angelone.png',
  'assets/images/brokers/groww.png',
  'assets/images/brokers/dhan.png',
  'assets/images/brokers/mstock.png',
];

/// Equal-size square chip for rail distribution (fills parent).
Widget brokerLogoSquareChip(String assetPath) {
  return Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black12),
      color: Colors.white,
    ),
    child: Image.asset(
      assetPath,
      package: _pkg,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );
}

/// Compact logo + label row for dropdown items (logo on white chip for contrast).
Widget brokerDropdownLabel(String code, {double logoSize = 22}) {
  final path = brokerLogoAsset(code);
  return Row(
    children: [
      Container(
        width: logoSize + 10,
        height: logoSize + 10,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: path != null
            ? Image.asset(
                path,
                package: _pkg,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    brokerLetterAvatar(code, size: logoSize),
              )
            : brokerLetterAvatar(code, size: logoSize),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          brokerDisplayName(code),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// Small logo image, or [fallback] icon when asset is missing / unknown.
Widget brokerLogoOrIcon({
  required String? brokerId,
  required IconData fallback,
  Color? fallbackColor,
  double size = 22,
}) {
  final path = brokerLogoAsset(brokerId);
  if (path == null) {
    return Icon(fallback, color: fallbackColor, size: size * 0.7);
  }
  return Image.asset(
    path,
    package: _pkg,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) =>
        Icon(fallback, color: fallbackColor, size: size * 0.7),
  );
}

Widget brokerLogoAssetImage(String assetPath, {double height = 18}) {
  return Image.asset(
    assetPath,
    package: _pkg,
    height: height,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => SizedBox(height: height, width: height),
  );
}
