/// Portfolio analytics request model
class PortfolioAnalyticsRequest {
  const PortfolioAnalyticsRequest({
    required this.coreIdentifiers,
    required this.featureToggles,
    required this.featureConfiguration,
    required this.pagination,
  });
  final CoreIdentifiers coreIdentifiers;
  final FeatureToggles featureToggles;
  final FeatureConfiguration featureConfiguration;
  final Pagination pagination;
}

/// Core identifiers for analytics request
class CoreIdentifiers {
  const CoreIdentifiers({required this.portfolioId});
  final String portfolioId;
}

/// Feature toggles to control analytics inclusion
class FeatureToggles {
  const FeatureToggles({
    required this.includeHeatmap,
    required this.includeMovers,
    required this.includeSectorAllocation,
    required this.includeMarketCapAllocation,
  });
  final bool includeHeatmap;
  final bool includeMovers;
  final bool includeSectorAllocation;
  final bool includeMarketCapAllocation;
}

/// Configuration for analytics features
class FeatureConfiguration {
  const FeatureConfiguration({required this.moversLimit});
  final int moversLimit;
}

/// Pagination configuration
class Pagination {
  const Pagination({
    required this.page,
    required this.size,
    required this.sortBy,
    required this.sortDirection,
    required this.returnAllData,
  });
  final int page;
  final int size;
  final String sortBy;
  final String sortDirection;
  final bool returnAllData;
}
