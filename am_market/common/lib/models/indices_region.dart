/// Which indices universe the Market Data UI is showing.
enum IndicesRegion {
  indian,
  global,
}

extension IndicesRegionLabel on IndicesRegion {
  String get label {
    switch (this) {
      case IndicesRegion.indian:
        return 'Indian';
      case IndicesRegion.global:
        return 'Global';
    }
  }
}
