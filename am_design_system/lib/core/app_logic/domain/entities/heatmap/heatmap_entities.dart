/// Core heatmap entities
/// These represent the domain layer data structures

/// Metadata for heatmap data
class HeatmapMetadata {
  const HeatmapMetadata({
    required this.dataSource,
    required this.lastUpdated,
    this.additionalInfo,
    this.tags,
  });

  final String dataSource;
  final DateTime lastUpdated;
  final Map<String, dynamic>? additionalInfo;
  final List<String>? tags;

  HeatmapMetadata copyWith({
    String? dataSource,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalInfo,
    List<String>? tags,
  }) =>
      HeatmapMetadata(
        dataSource: dataSource ?? this.dataSource,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        additionalInfo: additionalInfo ?? this.additionalInfo,
        tags: tags ?? this.tags,
      );
}

/// Base entity for heatmap tiles
class HeatmapTileEntity {
  const HeatmapTileEntity({
    required this.id,
    required this.name,
    required this.displayName,
    required this.weightage,
    required this.performance,
    this.value,
    this.children,
    this.metadata,
  });

  final String id;
  final String name;
  final String displayName;
  final double weightage;
  final double performance;
  final double? value;
  final List<HeatmapTileEntity>? children;
  final Map<String, dynamic>? metadata;

  bool get hasChildren => children != null && children!.isNotEmpty;

  HeatmapTileEntity copyWith({
    String? id,
    String? name,
    String? displayName,
    double? weightage,
    double? performance,
    double? value,
    List<HeatmapTileEntity>? children,
    Map<String, dynamic>? metadata,
  }) =>
      HeatmapTileEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        weightage: weightage ?? this.weightage,
        performance: performance ?? this.performance,
        value: value ?? this.value,
        children: children ?? this.children,
        metadata: metadata ?? this.metadata,
      );
}

/// Base entity for heatmap data
class HeatmapDataEntity {
  const HeatmapDataEntity({
    required this.id,
    required this.title,
    required this.tiles,
    required this.metadata,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<HeatmapTileEntity> tiles;
  final HeatmapMetadata metadata;

  HeatmapDataEntity copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<HeatmapTileEntity>? tiles,
    HeatmapMetadata? metadata,
  }) =>
      HeatmapDataEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        tiles: tiles ?? this.tiles,
        metadata: metadata ?? this.metadata,
      );
}
