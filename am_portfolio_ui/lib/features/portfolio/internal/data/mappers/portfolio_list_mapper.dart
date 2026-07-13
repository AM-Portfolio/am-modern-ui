import 'package:am_design_system/am_design_system.dart';
import '../dtos/portfolio_list_dto.dart';
import '../../domain/entities/portfolio_list.dart';
import 'package:am_common/am_common.dart';

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
      // Map individual portfolio items
      final portfolioItems = dto.portfolios
          .map(
            (itemDto) {
              String name = itemDto.portfolioName;
              final lower = name.toLowerCase();
              if (lower.contains('grow')) {
                name = 'Groww';
              } else if (lower.contains('zerodha')) {
                name = 'Zerodha';
              } else if (lower.contains('dhan')) {
                name = 'Dhan';
              } else if (lower.contains('angelone') || lower.contains('angel one')) {
                name = 'Angel One';
              } else if (lower.contains('upstox')) {
                name = 'Upstox';
              } else if (lower.contains('mstock')) {
                name = 'MStock';
              } else if (lower.contains('kotak')) {
                name = 'Kotak';
              }
              
              return PortfolioItem(
                portfolioId: itemDto.portfolioId,
                portfolioName: name,
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
