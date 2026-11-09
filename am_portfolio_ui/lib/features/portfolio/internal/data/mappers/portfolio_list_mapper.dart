import 'package:am_design_system/am_design_system.dart';
import '../dtos/portfolio_list_dto.dart';
import '../../domain/entities/portfolio_list.dart';

/// Mapper class for Portfolio List operations
///
/// Handles conversion between DTO and domain entities for portfolio list operations
class PortfolioListMapper {
  /// Convert PortfolioListDto to PortfolioList domain entity
  static PortfolioList fromApiModel(PortfolioListDto dto, ) {
    CommonLogger.debug(
      'Mapping PortfolioListDto to PortfolioList domain entity',
      tag: 'PortfolioListMapper',
    );

    try {
      // Hide CDSL only when another real (non-demo/paper) broker exists.
      final active = dto.portfolios
          .where((itemDto) => itemDto.kind?.toUpperCase() != 'DELETED')
          .toList();
      final hasOtherRealBroker = active.any((itemDto) {
        if (_isCdslDto(itemDto)) return false;
        final kind = itemDto.kind?.toUpperCase();
        final name = itemDto.portfolioName.toLowerCase();
        final isDemo = itemDto.isDummy ||
            kind == 'DUMMY' ||
            kind == 'DEMO' ||
            name.contains('demo');
        final isPaper = kind == 'PAPER' || name == 'paper';
        if (isDemo || isPaper || kind == 'BASKET') return false;
        return true;
      });

      final portfolioItems = active
          .where((itemDto) => !hasOtherRealBroker || !_isCdslDto(itemDto))
          .map(
            (itemDto) {
              String name = itemDto.portfolioName;
              final opaque = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(name.trim()) ||
                  RegExp(
                    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                  ).hasMatch(name.trim());
              if (opaque &&
                  itemDto.brokerType != null &&
                  itemDto.brokerType!.trim().isNotEmpty) {
                name = itemDto.brokerType!;
              }
              final lower = name.toLowerCase();
              if (lower.contains('grow')) {
                name = 'Groww';
              } else if (lower.contains('zerodha')) {
                name = 'Zerodha';
              } else if (lower.contains('dhan')) {
                name = 'Dhan';
              } else if (lower.contains('angelone') ||
                  lower.contains('angel one') ||
                  lower == 'angel_one') {
                name = 'Angel One';
              } else if (lower.contains('upstox')) {
                name = 'Upstox';
              } else if (lower.contains('mstock')) {
                name = 'MStock';
              } else if (lower.contains('kotak')) {
                name = 'Kotak';
              } else if (opaque) {
                name = 'Portfolio';
              }

              final kind = itemDto.kind?.toUpperCase();
              final isDummy = itemDto.isDummy ||
                  kind == 'DUMMY' ||
                  kind == 'DEMO' ||
                  name.toLowerCase().contains('demo');
              final isPaper =
                  kind == 'PAPER' || name.toLowerCase() == 'paper';
              final hasHoldings = isPaper ||
                  isDummy ||
                  (itemDto.hasHoldings ??
                      ((itemDto.assetCount != null &&
                              itemDto.assetCount! > 0) ||
                          (itemDto.totalValue != null &&
                              itemDto.totalValue! > 0) ||
                          itemDto.assetCount == null));
              final famId = itemDto.familyMemberId?.trim();
              final famName = itemDto.familyMemberName?.trim();
              return PortfolioItem(
                portfolioId: itemDto.portfolioId,
                portfolioName: name,
                isBasket: kind == 'BASKET',
                isDummy: isDummy,
                hasHoldings: hasHoldings,
                brokerType: itemDto.brokerType,
                familyMemberId:
                    (famId == null || famId.isEmpty) ? null : famId,
                familyMemberName:
                    (famName == null || famName.isEmpty) ? null : famName,
              );
            },
          )
          .toList();

      // Create domain entity
      final portfolioList = PortfolioList(
        portfolios: portfolioItems,
        lastUpdated: DateTime.now(),
      );

      CommonLogger.debug(
        'Successfully mapped ${portfolioItems.length} portfolio items to domain entity',
        tag: 'PortfolioListMapper',
      );

      return portfolioList;
    } catch (e) {
      CommonLogger.error(
        'Failed to map PortfolioListDto to domain entity',
        tag: 'PortfolioListMapper',
        error: e,
      );
      throw Exception('Invalid portfolio list mapping: ${e.toString()}');
    }
  }

  static bool _isCdslDto(PortfolioItemDto itemDto) {
    final broker = (itemDto.brokerType ?? '').toUpperCase();
    // Named CAS demat books (Mirae/Finwizard/Mutual Funds) are not CDSL aggregators.
    if (broker == 'CAS_DEMAT') return false;
    if (broker == 'CDSL') return true;
    final n = itemDto.portfolioName.toLowerCase().trim();
    return n == 'cdsl'
        || n == 'cas'
        || n == 'cdsl cas'
        || n == 'cas aggregator'
        || n.contains('cdsl');
  }

  /// Convert PortfolioList domain entity to PortfolioListDto
  static PortfolioListDto toApiModel(PortfolioList entity) {
    CommonLogger.debug(
      'Mapping PortfolioList domain entity to PortfolioListDto',
      tag: 'PortfolioListMapper',
    );

    try {
      // Map individual portfolio items
      final portfolioItemDtos = entity.portfolios
          .map(
            (item) => PortfolioItemDto(
              portfolioId: item.portfolioId,
              portfolioName: item.portfolioName,
              brokerType: item.brokerType,
              familyMemberId: item.familyMemberId,
              familyMemberName: item.familyMemberName,
            ),
          )
          .toList();

      // Create DTO
      final portfolioListDto = PortfolioListDto(portfolios: portfolioItemDtos);

      CommonLogger.debug(
        'Successfully mapped ${portfolioItemDtos.length} portfolio items to DTO',
        tag: 'PortfolioListMapper',
      );

      return portfolioListDto;
    } catch (e) {
      CommonLogger.error(
        'Failed to map PortfolioList domain entity to DTO',
        tag: 'PortfolioListMapper',
        error: e,
      );
      throw Exception('Invalid portfolio list mapping: ${e.toString()}');
    }
  }

  /// Create empty PortfolioList for error scenarios
  static PortfolioList createEmpty() => PortfolioList(
    
    portfolios: [],
    lastUpdated: DateTime.now(),
  );

  /// Validate portfolio list data
  static bool isValidPortfolioList(PortfolioListDto dto) {
    try {
      // Check if the list exists and is not null
      if (dto.portfolios.isEmpty) {
        CommonLogger.debug(
          'Portfolio list is empty but valid',
          tag: 'PortfolioListMapper',
        );
        return true;
      }

      // Validate each portfolio item
      for (final item in dto.portfolios) {
        if (item.portfolioId.isEmpty || item.portfolioName.isEmpty) {
          CommonLogger.warning(
            'Invalid portfolio item found: ${item.toString()}',
            tag: 'PortfolioListMapper',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      CommonLogger.error(
        'Failed to validate portfolio list',
        tag: 'PortfolioListMapper',
        error: e,
      );
      return false;
    }
  }
}
