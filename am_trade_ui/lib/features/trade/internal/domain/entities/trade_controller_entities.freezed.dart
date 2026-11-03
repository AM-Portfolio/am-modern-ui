// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_controller_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DerivativeInfo {
  DerivativeTypes? get derivativeType;
  double? get strikePrice;
  DateTime? get expiryDate;
  OptionTypes? get optionType;
  String? get underlyingSymbol;

  /// Create a copy of DerivativeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DerivativeInfoCopyWith<DerivativeInfo> get copyWith =>
      _$DerivativeInfoCopyWithImpl<DerivativeInfo>(
          this as DerivativeInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DerivativeInfo &&
            (identical(other.derivativeType, derivativeType) ||
                other.derivativeType == derivativeType) &&
            (identical(other.strikePrice, strikePrice) ||
                other.strikePrice == strikePrice) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.optionType, optionType) ||
                other.optionType == optionType) &&
            (identical(other.underlyingSymbol, underlyingSymbol) ||
                other.underlyingSymbol == underlyingSymbol));
  }

  @override
  int get hashCode => Object.hash(runtimeType, derivativeType, strikePrice,
      expiryDate, optionType, underlyingSymbol);

  @override
  String toString() {
    return 'DerivativeInfo(derivativeType: $derivativeType, strikePrice: $strikePrice, expiryDate: $expiryDate, optionType: $optionType, underlyingSymbol: $underlyingSymbol)';
  }
}

/// @nodoc
abstract mixin class $DerivativeInfoCopyWith<$Res> {
  factory $DerivativeInfoCopyWith(
          DerivativeInfo value, $Res Function(DerivativeInfo) _then) =
      _$DerivativeInfoCopyWithImpl;
  @useResult
  $Res call(
      {DerivativeTypes? derivativeType,
      double? strikePrice,
      DateTime? expiryDate,
      OptionTypes? optionType,
      String? underlyingSymbol});
}

/// @nodoc
class _$DerivativeInfoCopyWithImpl<$Res>
    implements $DerivativeInfoCopyWith<$Res> {
  _$DerivativeInfoCopyWithImpl(this._self, this._then);

  final DerivativeInfo _self;
  final $Res Function(DerivativeInfo) _then;

  /// Create a copy of DerivativeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? derivativeType = freezed,
    Object? strikePrice = freezed,
    Object? expiryDate = freezed,
    Object? optionType = freezed,
    Object? underlyingSymbol = freezed,
  }) {
    return _then(_self.copyWith(
      derivativeType: freezed == derivativeType
          ? _self.derivativeType
          : derivativeType // ignore: cast_nullable_to_non_nullable
              as DerivativeTypes?,
      strikePrice: freezed == strikePrice
          ? _self.strikePrice
          : strikePrice // ignore: cast_nullable_to_non_nullable
              as double?,
      expiryDate: freezed == expiryDate
          ? _self.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      optionType: freezed == optionType
          ? _self.optionType
          : optionType // ignore: cast_nullable_to_non_nullable
              as OptionTypes?,
      underlyingSymbol: freezed == underlyingSymbol
          ? _self.underlyingSymbol
          : underlyingSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [DerivativeInfo].
extension DerivativeInfoPatterns on DerivativeInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DerivativeInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DerivativeInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DerivativeInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DerivativeInfo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DerivativeInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DerivativeInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            DerivativeTypes? derivativeType,
            double? strikePrice,
            DateTime? expiryDate,
            OptionTypes? optionType,
            String? underlyingSymbol)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DerivativeInfo() when $default != null:
        return $default(_that.derivativeType, _that.strikePrice,
            _that.expiryDate, _that.optionType, _that.underlyingSymbol);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            DerivativeTypes? derivativeType,
            double? strikePrice,
            DateTime? expiryDate,
            OptionTypes? optionType,
            String? underlyingSymbol)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DerivativeInfo():
        return $default(_that.derivativeType, _that.strikePrice,
            _that.expiryDate, _that.optionType, _that.underlyingSymbol);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            DerivativeTypes? derivativeType,
            double? strikePrice,
            DateTime? expiryDate,
            OptionTypes? optionType,
            String? underlyingSymbol)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DerivativeInfo() when $default != null:
        return $default(_that.derivativeType, _that.strikePrice,
            _that.expiryDate, _that.optionType, _that.underlyingSymbol);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DerivativeInfo implements DerivativeInfo {
  const _DerivativeInfo(
      {this.derivativeType,
      this.strikePrice,
      this.expiryDate,
      this.optionType,
      this.underlyingSymbol});

  @override
  final DerivativeTypes? derivativeType;
  @override
  final double? strikePrice;
  @override
  final DateTime? expiryDate;
  @override
  final OptionTypes? optionType;
  @override
  final String? underlyingSymbol;

  /// Create a copy of DerivativeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DerivativeInfoCopyWith<_DerivativeInfo> get copyWith =>
      __$DerivativeInfoCopyWithImpl<_DerivativeInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DerivativeInfo &&
            (identical(other.derivativeType, derivativeType) ||
                other.derivativeType == derivativeType) &&
            (identical(other.strikePrice, strikePrice) ||
                other.strikePrice == strikePrice) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.optionType, optionType) ||
                other.optionType == optionType) &&
            (identical(other.underlyingSymbol, underlyingSymbol) ||
                other.underlyingSymbol == underlyingSymbol));
  }

  @override
  int get hashCode => Object.hash(runtimeType, derivativeType, strikePrice,
      expiryDate, optionType, underlyingSymbol);

  @override
  String toString() {
    return 'DerivativeInfo(derivativeType: $derivativeType, strikePrice: $strikePrice, expiryDate: $expiryDate, optionType: $optionType, underlyingSymbol: $underlyingSymbol)';
  }
}

/// @nodoc
abstract mixin class _$DerivativeInfoCopyWith<$Res>
    implements $DerivativeInfoCopyWith<$Res> {
  factory _$DerivativeInfoCopyWith(
          _DerivativeInfo value, $Res Function(_DerivativeInfo) _then) =
      __$DerivativeInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DerivativeTypes? derivativeType,
      double? strikePrice,
      DateTime? expiryDate,
      OptionTypes? optionType,
      String? underlyingSymbol});
}

/// @nodoc
class __$DerivativeInfoCopyWithImpl<$Res>
    implements _$DerivativeInfoCopyWith<$Res> {
  __$DerivativeInfoCopyWithImpl(this._self, this._then);

  final _DerivativeInfo _self;
  final $Res Function(_DerivativeInfo) _then;

  /// Create a copy of DerivativeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? derivativeType = freezed,
    Object? strikePrice = freezed,
    Object? expiryDate = freezed,
    Object? optionType = freezed,
    Object? underlyingSymbol = freezed,
  }) {
    return _then(_DerivativeInfo(
      derivativeType: freezed == derivativeType
          ? _self.derivativeType
          : derivativeType // ignore: cast_nullable_to_non_nullable
              as DerivativeTypes?,
      strikePrice: freezed == strikePrice
          ? _self.strikePrice
          : strikePrice // ignore: cast_nullable_to_non_nullable
              as double?,
      expiryDate: freezed == expiryDate
          ? _self.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      optionType: freezed == optionType
          ? _self.optionType
          : optionType // ignore: cast_nullable_to_non_nullable
              as OptionTypes?,
      underlyingSymbol: freezed == underlyingSymbol
          ? _self.underlyingSymbol
          : underlyingSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$InstrumentInfo {
  String? get symbol;
  String? get isin;
  String? get rawSymbol;
  ExchangeTypes? get exchange;
  MarketSegments? get segment;
  SeriesTypes? get series;
  IndexTypes? get indexType;
  DerivativeInfo? get derivativeInfo;
  String? get description;
  String? get currency;
  String? get lotSize;

  /// Create a copy of InstrumentInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InstrumentInfoCopyWith<InstrumentInfo> get copyWith =>
      _$InstrumentInfoCopyWithImpl<InstrumentInfo>(
          this as InstrumentInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InstrumentInfo &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.isin, isin) || other.isin == isin) &&
            (identical(other.rawSymbol, rawSymbol) ||
                other.rawSymbol == rawSymbol) &&
            (identical(other.exchange, exchange) ||
                other.exchange == exchange) &&
            (identical(other.segment, segment) || other.segment == segment) &&
            (identical(other.series, series) || other.series == series) &&
            (identical(other.indexType, indexType) ||
                other.indexType == indexType) &&
            (identical(other.derivativeInfo, derivativeInfo) ||
                other.derivativeInfo == derivativeInfo) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.lotSize, lotSize) || other.lotSize == lotSize));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      symbol,
      isin,
      rawSymbol,
      exchange,
      segment,
      series,
      indexType,
      derivativeInfo,
      description,
      currency,
      lotSize);

  @override
  String toString() {
    return 'InstrumentInfo(symbol: $symbol, isin: $isin, rawSymbol: $rawSymbol, exchange: $exchange, segment: $segment, series: $series, indexType: $indexType, derivativeInfo: $derivativeInfo, description: $description, currency: $currency, lotSize: $lotSize)';
  }
}

/// @nodoc
abstract mixin class $InstrumentInfoCopyWith<$Res> {
  factory $InstrumentInfoCopyWith(
          InstrumentInfo value, $Res Function(InstrumentInfo) _then) =
      _$InstrumentInfoCopyWithImpl;
  @useResult
  $Res call(
      {String? symbol,
      String? isin,
      String? rawSymbol,
      ExchangeTypes? exchange,
      MarketSegments? segment,
      SeriesTypes? series,
      IndexTypes? indexType,
      DerivativeInfo? derivativeInfo,
      String? description,
      String? currency,
      String? lotSize});

  $DerivativeInfoCopyWith<$Res>? get derivativeInfo;
}

/// @nodoc
class _$InstrumentInfoCopyWithImpl<$Res>
    implements $InstrumentInfoCopyWith<$Res> {
  _$InstrumentInfoCopyWithImpl(this._self, this._then);

  final InstrumentInfo _self;
  final $Res Function(InstrumentInfo) _then;

  /// Create a copy of InstrumentInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = freezed,
    Object? isin = freezed,
    Object? rawSymbol = freezed,
    Object? exchange = freezed,
    Object? segment = freezed,
    Object? series = freezed,
    Object? indexType = freezed,
    Object? derivativeInfo = freezed,
    Object? description = freezed,
    Object? currency = freezed,
    Object? lotSize = freezed,
  }) {
    return _then(_self.copyWith(
      symbol: freezed == symbol
          ? _self.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String?,
      isin: freezed == isin
          ? _self.isin
          : isin // ignore: cast_nullable_to_non_nullable
              as String?,
      rawSymbol: freezed == rawSymbol
          ? _self.rawSymbol
          : rawSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      exchange: freezed == exchange
          ? _self.exchange
          : exchange // ignore: cast_nullable_to_non_nullable
              as ExchangeTypes?,
      segment: freezed == segment
          ? _self.segment
          : segment // ignore: cast_nullable_to_non_nullable
              as MarketSegments?,
      series: freezed == series
          ? _self.series
          : series // ignore: cast_nullable_to_non_nullable
              as SeriesTypes?,
      indexType: freezed == indexType
          ? _self.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as IndexTypes?,
      derivativeInfo: freezed == derivativeInfo
          ? _self.derivativeInfo
          : derivativeInfo // ignore: cast_nullable_to_non_nullable
              as DerivativeInfo?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      currency: freezed == currency
          ? _self.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String?,
      lotSize: freezed == lotSize
          ? _self.lotSize
          : lotSize // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of InstrumentInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DerivativeInfoCopyWith<$Res>? get derivativeInfo {
    if (_self.derivativeInfo == null) {
      return null;
    }

    return $DerivativeInfoCopyWith<$Res>(_self.derivativeInfo!, (value) {
      return _then(_self.copyWith(derivativeInfo: value));
    });
  }
}

/// Adds pattern-matching-related methods to [InstrumentInfo].
extension InstrumentInfoPatterns on InstrumentInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_InstrumentInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InstrumentInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_InstrumentInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InstrumentInfo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_InstrumentInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InstrumentInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String? symbol,
            String? isin,
            String? rawSymbol,
            ExchangeTypes? exchange,
            MarketSegments? segment,
            SeriesTypes? series,
            IndexTypes? indexType,
            DerivativeInfo? derivativeInfo,
            String? description,
            String? currency,
            String? lotSize)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InstrumentInfo() when $default != null:
        return $default(
            _that.symbol,
            _that.isin,
            _that.rawSymbol,
            _that.exchange,
            _that.segment,
            _that.series,
            _that.indexType,
            _that.derivativeInfo,
            _that.description,
            _that.currency,
            _that.lotSize);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String? symbol,
            String? isin,
            String? rawSymbol,
            ExchangeTypes? exchange,
            MarketSegments? segment,
            SeriesTypes? series,
            IndexTypes? indexType,
            DerivativeInfo? derivativeInfo,
            String? description,
            String? currency,
            String? lotSize)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InstrumentInfo():
        return $default(
            _that.symbol,
            _that.isin,
            _that.rawSymbol,
            _that.exchange,
            _that.segment,
            _that.series,
            _that.indexType,
            _that.derivativeInfo,
            _that.description,
            _that.currency,
            _that.lotSize);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String? symbol,
            String? isin,
            String? rawSymbol,
            ExchangeTypes? exchange,
            MarketSegments? segment,
            SeriesTypes? series,
            IndexTypes? indexType,
            DerivativeInfo? derivativeInfo,
            String? description,
            String? currency,
            String? lotSize)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InstrumentInfo() when $default != null:
        return $default(
            _that.symbol,
            _that.isin,
            _that.rawSymbol,
            _that.exchange,
            _that.segment,
            _that.series,
            _that.indexType,
            _that.derivativeInfo,
            _that.description,
            _that.currency,
            _that.lotSize);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _InstrumentInfo implements InstrumentInfo {
  const _InstrumentInfo(
      {this.symbol,
      this.isin,
      this.rawSymbol,
      this.exchange,
      this.segment,
      this.series,
      this.indexType,
      this.derivativeInfo,
      this.description,
      this.currency,
      this.lotSize});

  @override
  final String? symbol;
  @override
  final String? isin;
  @override
  final String? rawSymbol;
  @override
  final ExchangeTypes? exchange;
  @override
  final MarketSegments? segment;
  @override
  final SeriesTypes? series;
  @override
  final IndexTypes? indexType;
  @override
  final DerivativeInfo? derivativeInfo;
  @override
  final String? description;
  @override
  final String? currency;
  @override
  final String? lotSize;

  /// Create a copy of InstrumentInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InstrumentInfoCopyWith<_InstrumentInfo> get copyWith =>
      __$InstrumentInfoCopyWithImpl<_InstrumentInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InstrumentInfo &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.isin, isin) || other.isin == isin) &&
            (identical(other.rawSymbol, rawSymbol) ||
                other.rawSymbol == rawSymbol) &&
            (identical(other.exchange, exchange) ||
                other.exchange == exchange) &&
            (identical(other.segment, segment) || other.segment == segment) &&
            (identical(other.series, series) || other.series == series) &&
            (identical(other.indexType, indexType) ||
                other.indexType == indexType) &&
            (identical(other.derivativeInfo, derivativeInfo) ||
                other.derivativeInfo == derivativeInfo) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.lotSize, lotSize) || other.lotSize == lotSize));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      symbol,
      isin,
      rawSymbol,
      exchange,
      segment,
      series,
      indexType,
      derivativeInfo,
      description,
      currency,
      lotSize);

  @override
  String toString() {
    return 'InstrumentInfo(symbol: $symbol, isin: $isin, rawSymbol: $rawSymbol, exchange: $exchange, segment: $segment, series: $series, indexType: $indexType, derivativeInfo: $derivativeInfo, description: $description, currency: $currency, lotSize: $lotSize)';
  }
}

/// @nodoc
abstract mixin class _$InstrumentInfoCopyWith<$Res>
    implements $InstrumentInfoCopyWith<$Res> {
  factory _$InstrumentInfoCopyWith(
          _InstrumentInfo value, $Res Function(_InstrumentInfo) _then) =
      __$InstrumentInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? symbol,
      String? isin,
      String? rawSymbol,
      ExchangeTypes? exchange,
      MarketSegments? segment,
      SeriesTypes? series,
      IndexTypes? indexType,
      DerivativeInfo? derivativeInfo,
      String? description,
      String? currency,
      String? lotSize});

  @override
  $DerivativeInfoCopyWith<$Res>? get derivativeInfo;
}

/// @nodoc
class __$InstrumentInfoCopyWithImpl<$Res>
    implements _$InstrumentInfoCopyWith<$Res> {
  __$InstrumentInfoCopyWithImpl(this._self, this._then);

  final _InstrumentInfo _self;
  final $Res Function(_InstrumentInfo) _then;

  /// Create a copy of InstrumentInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? symbol = freezed,
    Object? isin = freezed,
    Object? rawSymbol = freezed,
    Object? exchange = freezed,
    Object? segment = freezed,
    Object? series = freezed,
    Object? indexType = freezed,
    Object? derivativeInfo = freezed,
    Object? description = freezed,
    Object? currency = freezed,
    Object? lotSize = freezed,
  }) {
    return _then(_InstrumentInfo(
      symbol: freezed == symbol
          ? _self.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String?,
      isin: freezed == isin
          ? _self.isin
          : isin // ignore: cast_nullable_to_non_nullable
              as String?,
      rawSymbol: freezed == rawSymbol
          ? _self.rawSymbol
          : rawSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      exchange: freezed == exchange
          ? _self.exchange
          : exchange // ignore: cast_nullable_to_non_nullable
              as ExchangeTypes?,
      segment: freezed == segment
          ? _self.segment
          : segment // ignore: cast_nullable_to_non_nullable
              as MarketSegments?,
      series: freezed == series
          ? _self.series
          : series // ignore: cast_nullable_to_non_nullable
              as SeriesTypes?,
      indexType: freezed == indexType
          ? _self.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as IndexTypes?,
      derivativeInfo: freezed == derivativeInfo
          ? _self.derivativeInfo
          : derivativeInfo // ignore: cast_nullable_to_non_nullable
              as DerivativeInfo?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      currency: freezed == currency
          ? _self.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String?,
      lotSize: freezed == lotSize
          ? _self.lotSize
          : lotSize // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of InstrumentInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DerivativeInfoCopyWith<$Res>? get derivativeInfo {
    if (_self.derivativeInfo == null) {
      return null;
    }

    return $DerivativeInfoCopyWith<$Res>(_self.derivativeInfo!, (value) {
      return _then(_self.copyWith(derivativeInfo: value));
    });
  }
}

/// @nodoc
mixin _$EntryExitInfo {
  DateTime? get timestamp;
  double? get price;
  int? get quantity;
  double? get totalValue;
  double? get fees;
  String? get reason;

  /// Create a copy of EntryExitInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EntryExitInfoCopyWith<EntryExitInfo> get copyWith =>
      _$EntryExitInfoCopyWithImpl<EntryExitInfo>(
          this as EntryExitInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EntryExitInfo &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.totalValue, totalValue) ||
                other.totalValue == totalValue) &&
            (identical(other.fees, fees) || other.fees == fees) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, timestamp, price, quantity, totalValue, fees, reason);

  @override
  String toString() {
    return 'EntryExitInfo(timestamp: $timestamp, price: $price, quantity: $quantity, totalValue: $totalValue, fees: $fees, reason: $reason)';
  }
}

/// @nodoc
abstract mixin class $EntryExitInfoCopyWith<$Res> {
  factory $EntryExitInfoCopyWith(
          EntryExitInfo value, $Res Function(EntryExitInfo) _then) =
      _$EntryExitInfoCopyWithImpl;
  @useResult
  $Res call(
      {DateTime? timestamp,
      double? price,
      int? quantity,
      double? totalValue,
      double? fees,
      String? reason});
}

/// @nodoc
class _$EntryExitInfoCopyWithImpl<$Res>
    implements $EntryExitInfoCopyWith<$Res> {
  _$EntryExitInfoCopyWithImpl(this._self, this._then);

  final EntryExitInfo _self;
  final $Res Function(EntryExitInfo) _then;

  /// Create a copy of EntryExitInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = freezed,
    Object? price = freezed,
    Object? quantity = freezed,
    Object? totalValue = freezed,
    Object? fees = freezed,
    Object? reason = freezed,
  }) {
    return _then(_self.copyWith(
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int?,
      totalValue: freezed == totalValue
          ? _self.totalValue
          : totalValue // ignore: cast_nullable_to_non_nullable
              as double?,
      fees: freezed == fees
          ? _self.fees
          : fees // ignore: cast_nullable_to_non_nullable
              as double?,
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [EntryExitInfo].
extension EntryExitInfoPatterns on EntryExitInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_EntryExitInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryExitInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_EntryExitInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryExitInfo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_EntryExitInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryExitInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(DateTime? timestamp, double? price, int? quantity,
            double? totalValue, double? fees, String? reason)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryExitInfo() when $default != null:
        return $default(_that.timestamp, _that.price, _that.quantity,
            _that.totalValue, _that.fees, _that.reason);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(DateTime? timestamp, double? price, int? quantity,
            double? totalValue, double? fees, String? reason)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryExitInfo():
        return $default(_that.timestamp, _that.price, _that.quantity,
            _that.totalValue, _that.fees, _that.reason);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(DateTime? timestamp, double? price, int? quantity,
            double? totalValue, double? fees, String? reason)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryExitInfo() when $default != null:
        return $default(_that.timestamp, _that.price, _that.quantity,
            _that.totalValue, _that.fees, _that.reason);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EntryExitInfo implements EntryExitInfo {
  const _EntryExitInfo(
      {this.timestamp,
      this.price,
      this.quantity,
      this.totalValue,
      this.fees,
      this.reason});

  @override
  final DateTime? timestamp;
  @override
  final double? price;
  @override
  final int? quantity;
  @override
  final double? totalValue;
  @override
  final double? fees;
  @override
  final String? reason;

  /// Create a copy of EntryExitInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EntryExitInfoCopyWith<_EntryExitInfo> get copyWith =>
      __$EntryExitInfoCopyWithImpl<_EntryExitInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EntryExitInfo &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.totalValue, totalValue) ||
                other.totalValue == totalValue) &&
            (identical(other.fees, fees) || other.fees == fees) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, timestamp, price, quantity, totalValue, fees, reason);

  @override
  String toString() {
    return 'EntryExitInfo(timestamp: $timestamp, price: $price, quantity: $quantity, totalValue: $totalValue, fees: $fees, reason: $reason)';
  }
}

/// @nodoc
abstract mixin class _$EntryExitInfoCopyWith<$Res>
    implements $EntryExitInfoCopyWith<$Res> {
  factory _$EntryExitInfoCopyWith(
          _EntryExitInfo value, $Res Function(_EntryExitInfo) _then) =
      __$EntryExitInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime? timestamp,
      double? price,
      int? quantity,
      double? totalValue,
      double? fees,
      String? reason});
}

/// @nodoc
class __$EntryExitInfoCopyWithImpl<$Res>
    implements _$EntryExitInfoCopyWith<$Res> {
  __$EntryExitInfoCopyWithImpl(this._self, this._then);

  final _EntryExitInfo _self;
  final $Res Function(_EntryExitInfo) _then;

  /// Create a copy of EntryExitInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? timestamp = freezed,
    Object? price = freezed,
    Object? quantity = freezed,
    Object? totalValue = freezed,
    Object? fees = freezed,
    Object? reason = freezed,
  }) {
    return _then(_EntryExitInfo(
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int?,
      totalValue: freezed == totalValue
          ? _self.totalValue
          : totalValue // ignore: cast_nullable_to_non_nullable
              as double?,
      fees: freezed == fees
          ? _self.fees
          : fees // ignore: cast_nullable_to_non_nullable
              as double?,
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$TradeMetrics {
  double? get profitLoss;
  double? get profitLossPercentage;
  double? get todayProfitLoss;
  double? get todayProfitLossPercentage;
  String? get unrealizedBasis;
  double? get returnOnEquity;
  double? get riskAmount;
  double? get rewardAmount;
  double? get riskRewardRatio;
  int? get holdingTimeDays;
  int? get holdingTimeHours;
  int? get holdingTimeMinutes;
  double? get maxAdverseExcursion;
  double? get maxFavorableExcursion;

  /// Create a copy of TradeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TradeMetricsCopyWith<TradeMetrics> get copyWith =>
      _$TradeMetricsCopyWithImpl<TradeMetrics>(
          this as TradeMetrics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TradeMetrics &&
            (identical(other.profitLoss, profitLoss) ||
                other.profitLoss == profitLoss) &&
            (identical(other.profitLossPercentage, profitLossPercentage) ||
                other.profitLossPercentage == profitLossPercentage) &&
            (identical(other.todayProfitLoss, todayProfitLoss) ||
                other.todayProfitLoss == todayProfitLoss) &&
            (identical(other.todayProfitLossPercentage,
                    todayProfitLossPercentage) ||
                other.todayProfitLossPercentage == todayProfitLossPercentage) &&
            (identical(other.unrealizedBasis, unrealizedBasis) ||
                other.unrealizedBasis == unrealizedBasis) &&
            (identical(other.returnOnEquity, returnOnEquity) ||
                other.returnOnEquity == returnOnEquity) &&
            (identical(other.riskAmount, riskAmount) ||
                other.riskAmount == riskAmount) &&
            (identical(other.rewardAmount, rewardAmount) ||
                other.rewardAmount == rewardAmount) &&
            (identical(other.riskRewardRatio, riskRewardRatio) ||
                other.riskRewardRatio == riskRewardRatio) &&
            (identical(other.holdingTimeDays, holdingTimeDays) ||
                other.holdingTimeDays == holdingTimeDays) &&
            (identical(other.holdingTimeHours, holdingTimeHours) ||
                other.holdingTimeHours == holdingTimeHours) &&
            (identical(other.holdingTimeMinutes, holdingTimeMinutes) ||
                other.holdingTimeMinutes == holdingTimeMinutes) &&
            (identical(other.maxAdverseExcursion, maxAdverseExcursion) ||
                other.maxAdverseExcursion == maxAdverseExcursion) &&
            (identical(other.maxFavorableExcursion, maxFavorableExcursion) ||
                other.maxFavorableExcursion == maxFavorableExcursion));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      profitLoss,
      profitLossPercentage,
      todayProfitLoss,
      todayProfitLossPercentage,
      unrealizedBasis,
      returnOnEquity,
      riskAmount,
      rewardAmount,
      riskRewardRatio,
      holdingTimeDays,
      holdingTimeHours,
      holdingTimeMinutes,
      maxAdverseExcursion,
      maxFavorableExcursion);

  @override
  String toString() {
    return 'TradeMetrics(profitLoss: $profitLoss, profitLossPercentage: $profitLossPercentage, todayProfitLoss: $todayProfitLoss, todayProfitLossPercentage: $todayProfitLossPercentage, unrealizedBasis: $unrealizedBasis, returnOnEquity: $returnOnEquity, riskAmount: $riskAmount, rewardAmount: $rewardAmount, riskRewardRatio: $riskRewardRatio, holdingTimeDays: $holdingTimeDays, holdingTimeHours: $holdingTimeHours, holdingTimeMinutes: $holdingTimeMinutes, maxAdverseExcursion: $maxAdverseExcursion, maxFavorableExcursion: $maxFavorableExcursion)';
  }
}

/// @nodoc
abstract mixin class $TradeMetricsCopyWith<$Res> {
  factory $TradeMetricsCopyWith(
          TradeMetrics value, $Res Function(TradeMetrics) _then) =
      _$TradeMetricsCopyWithImpl;
  @useResult
  $Res call(
      {double? profitLoss,
      double? profitLossPercentage,
      double? todayProfitLoss,
      double? todayProfitLossPercentage,
      String? unrealizedBasis,
      double? returnOnEquity,
      double? riskAmount,
      double? rewardAmount,
      double? riskRewardRatio,
      int? holdingTimeDays,
      int? holdingTimeHours,
      int? holdingTimeMinutes,
      double? maxAdverseExcursion,
      double? maxFavorableExcursion});
}

/// @nodoc
class _$TradeMetricsCopyWithImpl<$Res> implements $TradeMetricsCopyWith<$Res> {
  _$TradeMetricsCopyWithImpl(this._self, this._then);

  final TradeMetrics _self;
  final $Res Function(TradeMetrics) _then;

  /// Create a copy of TradeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profitLoss = freezed,
    Object? profitLossPercentage = freezed,
    Object? todayProfitLoss = freezed,
    Object? todayProfitLossPercentage = freezed,
    Object? unrealizedBasis = freezed,
    Object? returnOnEquity = freezed,
    Object? riskAmount = freezed,
    Object? rewardAmount = freezed,
    Object? riskRewardRatio = freezed,
    Object? holdingTimeDays = freezed,
    Object? holdingTimeHours = freezed,
    Object? holdingTimeMinutes = freezed,
    Object? maxAdverseExcursion = freezed,
    Object? maxFavorableExcursion = freezed,
  }) {
    return _then(_self.copyWith(
      profitLoss: freezed == profitLoss
          ? _self.profitLoss
          : profitLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      profitLossPercentage: freezed == profitLossPercentage
          ? _self.profitLossPercentage
          : profitLossPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      todayProfitLoss: freezed == todayProfitLoss
          ? _self.todayProfitLoss
          : todayProfitLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      todayProfitLossPercentage: freezed == todayProfitLossPercentage
          ? _self.todayProfitLossPercentage
          : todayProfitLossPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      unrealizedBasis: freezed == unrealizedBasis
          ? _self.unrealizedBasis
          : unrealizedBasis // ignore: cast_nullable_to_non_nullable
              as String?,
      returnOnEquity: freezed == returnOnEquity
          ? _self.returnOnEquity
          : returnOnEquity // ignore: cast_nullable_to_non_nullable
              as double?,
      riskAmount: freezed == riskAmount
          ? _self.riskAmount
          : riskAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      rewardAmount: freezed == rewardAmount
          ? _self.rewardAmount
          : rewardAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      riskRewardRatio: freezed == riskRewardRatio
          ? _self.riskRewardRatio
          : riskRewardRatio // ignore: cast_nullable_to_non_nullable
              as double?,
      holdingTimeDays: freezed == holdingTimeDays
          ? _self.holdingTimeDays
          : holdingTimeDays // ignore: cast_nullable_to_non_nullable
              as int?,
      holdingTimeHours: freezed == holdingTimeHours
          ? _self.holdingTimeHours
          : holdingTimeHours // ignore: cast_nullable_to_non_nullable
              as int?,
      holdingTimeMinutes: freezed == holdingTimeMinutes
          ? _self.holdingTimeMinutes
          : holdingTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      maxAdverseExcursion: freezed == maxAdverseExcursion
          ? _self.maxAdverseExcursion
          : maxAdverseExcursion // ignore: cast_nullable_to_non_nullable
              as double?,
      maxFavorableExcursion: freezed == maxFavorableExcursion
          ? _self.maxFavorableExcursion
          : maxFavorableExcursion // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TradeMetrics].
extension TradeMetricsPatterns on TradeMetrics {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TradeMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeMetrics() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TradeMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeMetrics():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TradeMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeMetrics() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            double? profitLoss,
            double? profitLossPercentage,
            double? todayProfitLoss,
            double? todayProfitLossPercentage,
            String? unrealizedBasis,
            double? returnOnEquity,
            double? riskAmount,
            double? rewardAmount,
            double? riskRewardRatio,
            int? holdingTimeDays,
            int? holdingTimeHours,
            int? holdingTimeMinutes,
            double? maxAdverseExcursion,
            double? maxFavorableExcursion)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeMetrics() when $default != null:
        return $default(
            _that.profitLoss,
            _that.profitLossPercentage,
            _that.todayProfitLoss,
            _that.todayProfitLossPercentage,
            _that.unrealizedBasis,
            _that.returnOnEquity,
            _that.riskAmount,
            _that.rewardAmount,
            _that.riskRewardRatio,
            _that.holdingTimeDays,
            _that.holdingTimeHours,
            _that.holdingTimeMinutes,
            _that.maxAdverseExcursion,
            _that.maxFavorableExcursion);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            double? profitLoss,
            double? profitLossPercentage,
            double? todayProfitLoss,
            double? todayProfitLossPercentage,
            String? unrealizedBasis,
            double? returnOnEquity,
            double? riskAmount,
            double? rewardAmount,
            double? riskRewardRatio,
            int? holdingTimeDays,
            int? holdingTimeHours,
            int? holdingTimeMinutes,
            double? maxAdverseExcursion,
            double? maxFavorableExcursion)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeMetrics():
        return $default(
            _that.profitLoss,
            _that.profitLossPercentage,
            _that.todayProfitLoss,
            _that.todayProfitLossPercentage,
            _that.unrealizedBasis,
            _that.returnOnEquity,
            _that.riskAmount,
            _that.rewardAmount,
            _that.riskRewardRatio,
            _that.holdingTimeDays,
            _that.holdingTimeHours,
            _that.holdingTimeMinutes,
            _that.maxAdverseExcursion,
            _that.maxFavorableExcursion);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            double? profitLoss,
            double? profitLossPercentage,
            double? todayProfitLoss,
            double? todayProfitLossPercentage,
            String? unrealizedBasis,
            double? returnOnEquity,
            double? riskAmount,
            double? rewardAmount,
            double? riskRewardRatio,
            int? holdingTimeDays,
            int? holdingTimeHours,
            int? holdingTimeMinutes,
            double? maxAdverseExcursion,
            double? maxFavorableExcursion)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeMetrics() when $default != null:
        return $default(
            _that.profitLoss,
            _that.profitLossPercentage,
            _that.todayProfitLoss,
            _that.todayProfitLossPercentage,
            _that.unrealizedBasis,
            _that.returnOnEquity,
            _that.riskAmount,
            _that.rewardAmount,
            _that.riskRewardRatio,
            _that.holdingTimeDays,
            _that.holdingTimeHours,
            _that.holdingTimeMinutes,
            _that.maxAdverseExcursion,
            _that.maxFavorableExcursion);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TradeMetrics implements TradeMetrics {
  const _TradeMetrics(
      {this.profitLoss,
      this.profitLossPercentage,
      this.todayProfitLoss,
      this.todayProfitLossPercentage,
      this.unrealizedBasis,
      this.returnOnEquity,
      this.riskAmount,
      this.rewardAmount,
      this.riskRewardRatio,
      this.holdingTimeDays,
      this.holdingTimeHours,
      this.holdingTimeMinutes,
      this.maxAdverseExcursion,
      this.maxFavorableExcursion});

  @override
  final double? profitLoss;
  @override
  final double? profitLossPercentage;
  @override
  final double? todayProfitLoss;
  @override
  final double? todayProfitLossPercentage;
  @override
  final String? unrealizedBasis;
  @override
  final double? returnOnEquity;
  @override
  final double? riskAmount;
  @override
  final double? rewardAmount;
  @override
  final double? riskRewardRatio;
  @override
  final int? holdingTimeDays;
  @override
  final int? holdingTimeHours;
  @override
  final int? holdingTimeMinutes;
  @override
  final double? maxAdverseExcursion;
  @override
  final double? maxFavorableExcursion;

  /// Create a copy of TradeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TradeMetricsCopyWith<_TradeMetrics> get copyWith =>
      __$TradeMetricsCopyWithImpl<_TradeMetrics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TradeMetrics &&
            (identical(other.profitLoss, profitLoss) ||
                other.profitLoss == profitLoss) &&
            (identical(other.profitLossPercentage, profitLossPercentage) ||
                other.profitLossPercentage == profitLossPercentage) &&
            (identical(other.todayProfitLoss, todayProfitLoss) ||
                other.todayProfitLoss == todayProfitLoss) &&
            (identical(other.todayProfitLossPercentage,
                    todayProfitLossPercentage) ||
                other.todayProfitLossPercentage == todayProfitLossPercentage) &&
            (identical(other.unrealizedBasis, unrealizedBasis) ||
                other.unrealizedBasis == unrealizedBasis) &&
            (identical(other.returnOnEquity, returnOnEquity) ||
                other.returnOnEquity == returnOnEquity) &&
            (identical(other.riskAmount, riskAmount) ||
                other.riskAmount == riskAmount) &&
            (identical(other.rewardAmount, rewardAmount) ||
                other.rewardAmount == rewardAmount) &&
            (identical(other.riskRewardRatio, riskRewardRatio) ||
                other.riskRewardRatio == riskRewardRatio) &&
            (identical(other.holdingTimeDays, holdingTimeDays) ||
                other.holdingTimeDays == holdingTimeDays) &&
            (identical(other.holdingTimeHours, holdingTimeHours) ||
                other.holdingTimeHours == holdingTimeHours) &&
            (identical(other.holdingTimeMinutes, holdingTimeMinutes) ||
                other.holdingTimeMinutes == holdingTimeMinutes) &&
            (identical(other.maxAdverseExcursion, maxAdverseExcursion) ||
                other.maxAdverseExcursion == maxAdverseExcursion) &&
            (identical(other.maxFavorableExcursion, maxFavorableExcursion) ||
                other.maxFavorableExcursion == maxFavorableExcursion));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      profitLoss,
      profitLossPercentage,
      todayProfitLoss,
      todayProfitLossPercentage,
      unrealizedBasis,
      returnOnEquity,
      riskAmount,
      rewardAmount,
      riskRewardRatio,
      holdingTimeDays,
      holdingTimeHours,
      holdingTimeMinutes,
      maxAdverseExcursion,
      maxFavorableExcursion);

  @override
  String toString() {
    return 'TradeMetrics(profitLoss: $profitLoss, profitLossPercentage: $profitLossPercentage, todayProfitLoss: $todayProfitLoss, todayProfitLossPercentage: $todayProfitLossPercentage, unrealizedBasis: $unrealizedBasis, returnOnEquity: $returnOnEquity, riskAmount: $riskAmount, rewardAmount: $rewardAmount, riskRewardRatio: $riskRewardRatio, holdingTimeDays: $holdingTimeDays, holdingTimeHours: $holdingTimeHours, holdingTimeMinutes: $holdingTimeMinutes, maxAdverseExcursion: $maxAdverseExcursion, maxFavorableExcursion: $maxFavorableExcursion)';
  }
}

/// @nodoc
abstract mixin class _$TradeMetricsCopyWith<$Res>
    implements $TradeMetricsCopyWith<$Res> {
  factory _$TradeMetricsCopyWith(
          _TradeMetrics value, $Res Function(_TradeMetrics) _then) =
      __$TradeMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double? profitLoss,
      double? profitLossPercentage,
      double? todayProfitLoss,
      double? todayProfitLossPercentage,
      String? unrealizedBasis,
      double? returnOnEquity,
      double? riskAmount,
      double? rewardAmount,
      double? riskRewardRatio,
      int? holdingTimeDays,
      int? holdingTimeHours,
      int? holdingTimeMinutes,
      double? maxAdverseExcursion,
      double? maxFavorableExcursion});
}

/// @nodoc
class __$TradeMetricsCopyWithImpl<$Res>
    implements _$TradeMetricsCopyWith<$Res> {
  __$TradeMetricsCopyWithImpl(this._self, this._then);

  final _TradeMetrics _self;
  final $Res Function(_TradeMetrics) _then;

  /// Create a copy of TradeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? profitLoss = freezed,
    Object? profitLossPercentage = freezed,
    Object? todayProfitLoss = freezed,
    Object? todayProfitLossPercentage = freezed,
    Object? unrealizedBasis = freezed,
    Object? returnOnEquity = freezed,
    Object? riskAmount = freezed,
    Object? rewardAmount = freezed,
    Object? riskRewardRatio = freezed,
    Object? holdingTimeDays = freezed,
    Object? holdingTimeHours = freezed,
    Object? holdingTimeMinutes = freezed,
    Object? maxAdverseExcursion = freezed,
    Object? maxFavorableExcursion = freezed,
  }) {
    return _then(_TradeMetrics(
      profitLoss: freezed == profitLoss
          ? _self.profitLoss
          : profitLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      profitLossPercentage: freezed == profitLossPercentage
          ? _self.profitLossPercentage
          : profitLossPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      todayProfitLoss: freezed == todayProfitLoss
          ? _self.todayProfitLoss
          : todayProfitLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      todayProfitLossPercentage: freezed == todayProfitLossPercentage
          ? _self.todayProfitLossPercentage
          : todayProfitLossPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      unrealizedBasis: freezed == unrealizedBasis
          ? _self.unrealizedBasis
          : unrealizedBasis // ignore: cast_nullable_to_non_nullable
              as String?,
      returnOnEquity: freezed == returnOnEquity
          ? _self.returnOnEquity
          : returnOnEquity // ignore: cast_nullable_to_non_nullable
              as double?,
      riskAmount: freezed == riskAmount
          ? _self.riskAmount
          : riskAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      rewardAmount: freezed == rewardAmount
          ? _self.rewardAmount
          : rewardAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      riskRewardRatio: freezed == riskRewardRatio
          ? _self.riskRewardRatio
          : riskRewardRatio // ignore: cast_nullable_to_non_nullable
              as double?,
      holdingTimeDays: freezed == holdingTimeDays
          ? _self.holdingTimeDays
          : holdingTimeDays // ignore: cast_nullable_to_non_nullable
              as int?,
      holdingTimeHours: freezed == holdingTimeHours
          ? _self.holdingTimeHours
          : holdingTimeHours // ignore: cast_nullable_to_non_nullable
              as int?,
      holdingTimeMinutes: freezed == holdingTimeMinutes
          ? _self.holdingTimeMinutes
          : holdingTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      maxAdverseExcursion: freezed == maxAdverseExcursion
          ? _self.maxAdverseExcursion
          : maxAdverseExcursion // ignore: cast_nullable_to_non_nullable
              as double?,
      maxFavorableExcursion: freezed == maxFavorableExcursion
          ? _self.maxFavorableExcursion
          : maxFavorableExcursion // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
mixin _$Attachment {
  String? get fileName;
  String? get fileUrl;
  String? get fileType;
  DateTime? get uploadedAt;
  String? get description;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AttachmentCopyWith<Attachment> get copyWith =>
      _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Attachment &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, fileName, fileUrl, fileType, uploadedAt, description);

  @override
  String toString() {
    return 'Attachment(fileName: $fileName, fileUrl: $fileUrl, fileType: $fileType, uploadedAt: $uploadedAt, description: $description)';
  }
}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res> {
  factory $AttachmentCopyWith(
          Attachment value, $Res Function(Attachment) _then) =
      _$AttachmentCopyWithImpl;
  @useResult
  $Res call(
      {String? fileName,
      String? fileUrl,
      String? fileType,
      DateTime? uploadedAt,
      String? description});
}

/// @nodoc
class _$AttachmentCopyWithImpl<$Res> implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = freezed,
    Object? fileUrl = freezed,
    Object? fileType = freezed,
    Object? uploadedAt = freezed,
    Object? description = freezed,
  }) {
    return _then(_self.copyWith(
      fileName: freezed == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      fileUrl: freezed == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileType: freezed == fileType
          ? _self.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadedAt: freezed == uploadedAt
          ? _self.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Attachment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Attachment() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Attachment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attachment():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Attachment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attachment() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String? fileName, String? fileUrl, String? fileType,
            DateTime? uploadedAt, String? description)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Attachment() when $default != null:
        return $default(_that.fileName, _that.fileUrl, _that.fileType,
            _that.uploadedAt, _that.description);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String? fileName, String? fileUrl, String? fileType,
            DateTime? uploadedAt, String? description)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attachment():
        return $default(_that.fileName, _that.fileUrl, _that.fileType,
            _that.uploadedAt, _that.description);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String? fileName, String? fileUrl, String? fileType,
            DateTime? uploadedAt, String? description)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attachment() when $default != null:
        return $default(_that.fileName, _that.fileUrl, _that.fileType,
            _that.uploadedAt, _that.description);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Attachment implements Attachment {
  const _Attachment(
      {this.fileName,
      this.fileUrl,
      this.fileType,
      this.uploadedAt,
      this.description});

  @override
  final String? fileName;
  @override
  final String? fileUrl;
  @override
  final String? fileType;
  @override
  final DateTime? uploadedAt;
  @override
  final String? description;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AttachmentCopyWith<_Attachment> get copyWith =>
      __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Attachment &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, fileName, fileUrl, fileType, uploadedAt, description);

  @override
  String toString() {
    return 'Attachment(fileName: $fileName, fileUrl: $fileUrl, fileType: $fileType, uploadedAt: $uploadedAt, description: $description)';
  }
}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res>
    implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(
          _Attachment value, $Res Function(_Attachment) _then) =
      __$AttachmentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? fileName,
      String? fileUrl,
      String? fileType,
      DateTime? uploadedAt,
      String? description});
}

/// @nodoc
class __$AttachmentCopyWithImpl<$Res> implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fileName = freezed,
    Object? fileUrl = freezed,
    Object? fileType = freezed,
    Object? uploadedAt = freezed,
    Object? description = freezed,
  }) {
    return _then(_Attachment(
      fileName: freezed == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      fileUrl: freezed == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileType: freezed == fileType
          ? _self.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadedAt: freezed == uploadedAt
          ? _self.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$TradePsychologyData {
  List<EntryPsychologyFactors>? get entryPsychologyFactors;
  List<ExitPsychologyFactors>? get exitPsychologyFactors;
  List<BehaviorPatterns>? get behaviorPatterns;
  Map<String, List<String>>? get categorizedTags;
  String? get psychologyNotes;

  /// Create a copy of TradePsychologyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TradePsychologyDataCopyWith<TradePsychologyData> get copyWith =>
      _$TradePsychologyDataCopyWithImpl<TradePsychologyData>(
          this as TradePsychologyData, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TradePsychologyData &&
            const DeepCollectionEquality()
                .equals(other.entryPsychologyFactors, entryPsychologyFactors) &&
            const DeepCollectionEquality()
                .equals(other.exitPsychologyFactors, exitPsychologyFactors) &&
            const DeepCollectionEquality()
                .equals(other.behaviorPatterns, behaviorPatterns) &&
            const DeepCollectionEquality()
                .equals(other.categorizedTags, categorizedTags) &&
            (identical(other.psychologyNotes, psychologyNotes) ||
                other.psychologyNotes == psychologyNotes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(entryPsychologyFactors),
      const DeepCollectionEquality().hash(exitPsychologyFactors),
      const DeepCollectionEquality().hash(behaviorPatterns),
      const DeepCollectionEquality().hash(categorizedTags),
      psychologyNotes);

  @override
  String toString() {
    return 'TradePsychologyData(entryPsychologyFactors: $entryPsychologyFactors, exitPsychologyFactors: $exitPsychologyFactors, behaviorPatterns: $behaviorPatterns, categorizedTags: $categorizedTags, psychologyNotes: $psychologyNotes)';
  }
}

/// @nodoc
abstract mixin class $TradePsychologyDataCopyWith<$Res> {
  factory $TradePsychologyDataCopyWith(
          TradePsychologyData value, $Res Function(TradePsychologyData) _then) =
      _$TradePsychologyDataCopyWithImpl;
  @useResult
  $Res call(
      {List<EntryPsychologyFactors>? entryPsychologyFactors,
      List<ExitPsychologyFactors>? exitPsychologyFactors,
      List<BehaviorPatterns>? behaviorPatterns,
      Map<String, List<String>>? categorizedTags,
      String? psychologyNotes});
}

/// @nodoc
class _$TradePsychologyDataCopyWithImpl<$Res>
    implements $TradePsychologyDataCopyWith<$Res> {
  _$TradePsychologyDataCopyWithImpl(this._self, this._then);

  final TradePsychologyData _self;
  final $Res Function(TradePsychologyData) _then;

  /// Create a copy of TradePsychologyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entryPsychologyFactors = freezed,
    Object? exitPsychologyFactors = freezed,
    Object? behaviorPatterns = freezed,
    Object? categorizedTags = freezed,
    Object? psychologyNotes = freezed,
  }) {
    return _then(_self.copyWith(
      entryPsychologyFactors: freezed == entryPsychologyFactors
          ? _self.entryPsychologyFactors
          : entryPsychologyFactors // ignore: cast_nullable_to_non_nullable
              as List<EntryPsychologyFactors>?,
      exitPsychologyFactors: freezed == exitPsychologyFactors
          ? _self.exitPsychologyFactors
          : exitPsychologyFactors // ignore: cast_nullable_to_non_nullable
              as List<ExitPsychologyFactors>?,
      behaviorPatterns: freezed == behaviorPatterns
          ? _self.behaviorPatterns
          : behaviorPatterns // ignore: cast_nullable_to_non_nullable
              as List<BehaviorPatterns>?,
      categorizedTags: freezed == categorizedTags
          ? _self.categorizedTags
          : categorizedTags // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>?,
      psychologyNotes: freezed == psychologyNotes
          ? _self.psychologyNotes
          : psychologyNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TradePsychologyData].
extension TradePsychologyDataPatterns on TradePsychologyData {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TradePsychologyData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradePsychologyData() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TradePsychologyData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradePsychologyData():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TradePsychologyData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradePsychologyData() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<EntryPsychologyFactors>? entryPsychologyFactors,
            List<ExitPsychologyFactors>? exitPsychologyFactors,
            List<BehaviorPatterns>? behaviorPatterns,
            Map<String, List<String>>? categorizedTags,
            String? psychologyNotes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradePsychologyData() when $default != null:
        return $default(
            _that.entryPsychologyFactors,
            _that.exitPsychologyFactors,
            _that.behaviorPatterns,
            _that.categorizedTags,
            _that.psychologyNotes);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<EntryPsychologyFactors>? entryPsychologyFactors,
            List<ExitPsychologyFactors>? exitPsychologyFactors,
            List<BehaviorPatterns>? behaviorPatterns,
            Map<String, List<String>>? categorizedTags,
            String? psychologyNotes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradePsychologyData():
        return $default(
            _that.entryPsychologyFactors,
            _that.exitPsychologyFactors,
            _that.behaviorPatterns,
            _that.categorizedTags,
            _that.psychologyNotes);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<EntryPsychologyFactors>? entryPsychologyFactors,
            List<ExitPsychologyFactors>? exitPsychologyFactors,
            List<BehaviorPatterns>? behaviorPatterns,
            Map<String, List<String>>? categorizedTags,
            String? psychologyNotes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradePsychologyData() when $default != null:
        return $default(
            _that.entryPsychologyFactors,
            _that.exitPsychologyFactors,
            _that.behaviorPatterns,
            _that.categorizedTags,
            _that.psychologyNotes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TradePsychologyData implements TradePsychologyData {
  const _TradePsychologyData(
      {final List<EntryPsychologyFactors>? entryPsychologyFactors,
      final List<ExitPsychologyFactors>? exitPsychologyFactors,
      final List<BehaviorPatterns>? behaviorPatterns,
      final Map<String, List<String>>? categorizedTags,
      this.psychologyNotes})
      : _entryPsychologyFactors = entryPsychologyFactors,
        _exitPsychologyFactors = exitPsychologyFactors,
        _behaviorPatterns = behaviorPatterns,
        _categorizedTags = categorizedTags;

  final List<EntryPsychologyFactors>? _entryPsychologyFactors;
  @override
  List<EntryPsychologyFactors>? get entryPsychologyFactors {
    final value = _entryPsychologyFactors;
    if (value == null) return null;
    if (_entryPsychologyFactors is EqualUnmodifiableListView)
      return _entryPsychologyFactors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ExitPsychologyFactors>? _exitPsychologyFactors;
  @override
  List<ExitPsychologyFactors>? get exitPsychologyFactors {
    final value = _exitPsychologyFactors;
    if (value == null) return null;
    if (_exitPsychologyFactors is EqualUnmodifiableListView)
      return _exitPsychologyFactors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<BehaviorPatterns>? _behaviorPatterns;
  @override
  List<BehaviorPatterns>? get behaviorPatterns {
    final value = _behaviorPatterns;
    if (value == null) return null;
    if (_behaviorPatterns is EqualUnmodifiableListView)
      return _behaviorPatterns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, List<String>>? _categorizedTags;
  @override
  Map<String, List<String>>? get categorizedTags {
    final value = _categorizedTags;
    if (value == null) return null;
    if (_categorizedTags is EqualUnmodifiableMapView) return _categorizedTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? psychologyNotes;

  /// Create a copy of TradePsychologyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TradePsychologyDataCopyWith<_TradePsychologyData> get copyWith =>
      __$TradePsychologyDataCopyWithImpl<_TradePsychologyData>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TradePsychologyData &&
            const DeepCollectionEquality().equals(
                other._entryPsychologyFactors, _entryPsychologyFactors) &&
            const DeepCollectionEquality()
                .equals(other._exitPsychologyFactors, _exitPsychologyFactors) &&
            const DeepCollectionEquality()
                .equals(other._behaviorPatterns, _behaviorPatterns) &&
            const DeepCollectionEquality()
                .equals(other._categorizedTags, _categorizedTags) &&
            (identical(other.psychologyNotes, psychologyNotes) ||
                other.psychologyNotes == psychologyNotes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_entryPsychologyFactors),
      const DeepCollectionEquality().hash(_exitPsychologyFactors),
      const DeepCollectionEquality().hash(_behaviorPatterns),
      const DeepCollectionEquality().hash(_categorizedTags),
      psychologyNotes);

  @override
  String toString() {
    return 'TradePsychologyData(entryPsychologyFactors: $entryPsychologyFactors, exitPsychologyFactors: $exitPsychologyFactors, behaviorPatterns: $behaviorPatterns, categorizedTags: $categorizedTags, psychologyNotes: $psychologyNotes)';
  }
}

/// @nodoc
abstract mixin class _$TradePsychologyDataCopyWith<$Res>
    implements $TradePsychologyDataCopyWith<$Res> {
  factory _$TradePsychologyDataCopyWith(_TradePsychologyData value,
          $Res Function(_TradePsychologyData) _then) =
      __$TradePsychologyDataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<EntryPsychologyFactors>? entryPsychologyFactors,
      List<ExitPsychologyFactors>? exitPsychologyFactors,
      List<BehaviorPatterns>? behaviorPatterns,
      Map<String, List<String>>? categorizedTags,
      String? psychologyNotes});
}

/// @nodoc
class __$TradePsychologyDataCopyWithImpl<$Res>
    implements _$TradePsychologyDataCopyWith<$Res> {
  __$TradePsychologyDataCopyWithImpl(this._self, this._then);

  final _TradePsychologyData _self;
  final $Res Function(_TradePsychologyData) _then;

  /// Create a copy of TradePsychologyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entryPsychologyFactors = freezed,
    Object? exitPsychologyFactors = freezed,
    Object? behaviorPatterns = freezed,
    Object? categorizedTags = freezed,
    Object? psychologyNotes = freezed,
  }) {
    return _then(_TradePsychologyData(
      entryPsychologyFactors: freezed == entryPsychologyFactors
          ? _self._entryPsychologyFactors
          : entryPsychologyFactors // ignore: cast_nullable_to_non_nullable
              as List<EntryPsychologyFactors>?,
      exitPsychologyFactors: freezed == exitPsychologyFactors
          ? _self._exitPsychologyFactors
          : exitPsychologyFactors // ignore: cast_nullable_to_non_nullable
              as List<ExitPsychologyFactors>?,
      behaviorPatterns: freezed == behaviorPatterns
          ? _self._behaviorPatterns
          : behaviorPatterns // ignore: cast_nullable_to_non_nullable
              as List<BehaviorPatterns>?,
      categorizedTags: freezed == categorizedTags
          ? _self._categorizedTags
          : categorizedTags // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>?,
      psychologyNotes: freezed == psychologyNotes
          ? _self.psychologyNotes
          : psychologyNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$TradeEntryExitReasoning {
  List<TechnicalReasons>? get technicalReasons;
  List<FundamentalReasons>? get fundamentalReasons;
  String? get primaryReason;
  String? get reasoningSummary;
  int? get confidenceLevel;
  List<String>? get supportingIndicators;
  List<String>? get conflictingIndicators;
  String? get exitPrimaryReason;
  String? get exitReasoningSummary;
  int? get exitConfidenceLevel;
  List<String>? get exitSupportingIndicators;
  List<String>? get exitConflictingIndicators;
  int? get exitQualityScore;
  String? get strategy;

  /// Create a copy of TradeEntryExitReasoning
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TradeEntryExitReasoningCopyWith<TradeEntryExitReasoning> get copyWith =>
      _$TradeEntryExitReasoningCopyWithImpl<TradeEntryExitReasoning>(
          this as TradeEntryExitReasoning, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TradeEntryExitReasoning &&
            const DeepCollectionEquality()
                .equals(other.technicalReasons, technicalReasons) &&
            const DeepCollectionEquality()
                .equals(other.fundamentalReasons, fundamentalReasons) &&
            (identical(other.primaryReason, primaryReason) ||
                other.primaryReason == primaryReason) &&
            (identical(other.reasoningSummary, reasoningSummary) ||
                other.reasoningSummary == reasoningSummary) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel) &&
            const DeepCollectionEquality()
                .equals(other.supportingIndicators, supportingIndicators) &&
            const DeepCollectionEquality()
                .equals(other.conflictingIndicators, conflictingIndicators) &&
            (identical(other.exitPrimaryReason, exitPrimaryReason) ||
                other.exitPrimaryReason == exitPrimaryReason) &&
            (identical(other.exitReasoningSummary, exitReasoningSummary) ||
                other.exitReasoningSummary == exitReasoningSummary) &&
            (identical(other.exitConfidenceLevel, exitConfidenceLevel) ||
                other.exitConfidenceLevel == exitConfidenceLevel) &&
            const DeepCollectionEquality().equals(
                other.exitSupportingIndicators, exitSupportingIndicators) &&
            const DeepCollectionEquality().equals(
                other.exitConflictingIndicators, exitConflictingIndicators) &&
            (identical(other.exitQualityScore, exitQualityScore) ||
                other.exitQualityScore == exitQualityScore) &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(technicalReasons),
      const DeepCollectionEquality().hash(fundamentalReasons),
      primaryReason,
      reasoningSummary,
      confidenceLevel,
      const DeepCollectionEquality().hash(supportingIndicators),
      const DeepCollectionEquality().hash(conflictingIndicators),
      exitPrimaryReason,
      exitReasoningSummary,
      exitConfidenceLevel,
      const DeepCollectionEquality().hash(exitSupportingIndicators),
      const DeepCollectionEquality().hash(exitConflictingIndicators),
      exitQualityScore,
      strategy);

  @override
  String toString() {
    return 'TradeEntryExitReasoning(technicalReasons: $technicalReasons, fundamentalReasons: $fundamentalReasons, primaryReason: $primaryReason, reasoningSummary: $reasoningSummary, confidenceLevel: $confidenceLevel, supportingIndicators: $supportingIndicators, conflictingIndicators: $conflictingIndicators, exitPrimaryReason: $exitPrimaryReason, exitReasoningSummary: $exitReasoningSummary, exitConfidenceLevel: $exitConfidenceLevel, exitSupportingIndicators: $exitSupportingIndicators, exitConflictingIndicators: $exitConflictingIndicators, exitQualityScore: $exitQualityScore, strategy: $strategy)';
  }
}

/// @nodoc
abstract mixin class $TradeEntryExitReasoningCopyWith<$Res> {
  factory $TradeEntryExitReasoningCopyWith(TradeEntryExitReasoning value,
          $Res Function(TradeEntryExitReasoning) _then) =
      _$TradeEntryExitReasoningCopyWithImpl;
  @useResult
  $Res call(
      {List<TechnicalReasons>? technicalReasons,
      List<FundamentalReasons>? fundamentalReasons,
      String? primaryReason,
      String? reasoningSummary,
      int? confidenceLevel,
      List<String>? supportingIndicators,
      List<String>? conflictingIndicators,
      String? exitPrimaryReason,
      String? exitReasoningSummary,
      int? exitConfidenceLevel,
      List<String>? exitSupportingIndicators,
      List<String>? exitConflictingIndicators,
      int? exitQualityScore,
      String? strategy});
}

/// @nodoc
class _$TradeEntryExitReasoningCopyWithImpl<$Res>
    implements $TradeEntryExitReasoningCopyWith<$Res> {
  _$TradeEntryExitReasoningCopyWithImpl(this._self, this._then);

  final TradeEntryExitReasoning _self;
  final $Res Function(TradeEntryExitReasoning) _then;

  /// Create a copy of TradeEntryExitReasoning
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? technicalReasons = freezed,
    Object? fundamentalReasons = freezed,
    Object? primaryReason = freezed,
    Object? reasoningSummary = freezed,
    Object? confidenceLevel = freezed,
    Object? supportingIndicators = freezed,
    Object? conflictingIndicators = freezed,
    Object? exitPrimaryReason = freezed,
    Object? exitReasoningSummary = freezed,
    Object? exitConfidenceLevel = freezed,
    Object? exitSupportingIndicators = freezed,
    Object? exitConflictingIndicators = freezed,
    Object? exitQualityScore = freezed,
    Object? strategy = freezed,
  }) {
    return _then(_self.copyWith(
      technicalReasons: freezed == technicalReasons
          ? _self.technicalReasons
          : technicalReasons // ignore: cast_nullable_to_non_nullable
              as List<TechnicalReasons>?,
      fundamentalReasons: freezed == fundamentalReasons
          ? _self.fundamentalReasons
          : fundamentalReasons // ignore: cast_nullable_to_non_nullable
              as List<FundamentalReasons>?,
      primaryReason: freezed == primaryReason
          ? _self.primaryReason
          : primaryReason // ignore: cast_nullable_to_non_nullable
              as String?,
      reasoningSummary: freezed == reasoningSummary
          ? _self.reasoningSummary
          : reasoningSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      confidenceLevel: freezed == confidenceLevel
          ? _self.confidenceLevel
          : confidenceLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      supportingIndicators: freezed == supportingIndicators
          ? _self.supportingIndicators
          : supportingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      conflictingIndicators: freezed == conflictingIndicators
          ? _self.conflictingIndicators
          : conflictingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitPrimaryReason: freezed == exitPrimaryReason
          ? _self.exitPrimaryReason
          : exitPrimaryReason // ignore: cast_nullable_to_non_nullable
              as String?,
      exitReasoningSummary: freezed == exitReasoningSummary
          ? _self.exitReasoningSummary
          : exitReasoningSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      exitConfidenceLevel: freezed == exitConfidenceLevel
          ? _self.exitConfidenceLevel
          : exitConfidenceLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      exitSupportingIndicators: freezed == exitSupportingIndicators
          ? _self.exitSupportingIndicators
          : exitSupportingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitConflictingIndicators: freezed == exitConflictingIndicators
          ? _self.exitConflictingIndicators
          : exitConflictingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitQualityScore: freezed == exitQualityScore
          ? _self.exitQualityScore
          : exitQualityScore // ignore: cast_nullable_to_non_nullable
              as int?,
      strategy: freezed == strategy
          ? _self.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TradeEntryExitReasoning].
extension TradeEntryExitReasoningPatterns on TradeEntryExitReasoning {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TradeEntryExitReasoning value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeEntryExitReasoning() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TradeEntryExitReasoning value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeEntryExitReasoning():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TradeEntryExitReasoning value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeEntryExitReasoning() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<TechnicalReasons>? technicalReasons,
            List<FundamentalReasons>? fundamentalReasons,
            String? primaryReason,
            String? reasoningSummary,
            int? confidenceLevel,
            List<String>? supportingIndicators,
            List<String>? conflictingIndicators,
            String? exitPrimaryReason,
            String? exitReasoningSummary,
            int? exitConfidenceLevel,
            List<String>? exitSupportingIndicators,
            List<String>? exitConflictingIndicators,
            int? exitQualityScore,
            String? strategy)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeEntryExitReasoning() when $default != null:
        return $default(
            _that.technicalReasons,
            _that.fundamentalReasons,
            _that.primaryReason,
            _that.reasoningSummary,
            _that.confidenceLevel,
            _that.supportingIndicators,
            _that.conflictingIndicators,
            _that.exitPrimaryReason,
            _that.exitReasoningSummary,
            _that.exitConfidenceLevel,
            _that.exitSupportingIndicators,
            _that.exitConflictingIndicators,
            _that.exitQualityScore,
            _that.strategy);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<TechnicalReasons>? technicalReasons,
            List<FundamentalReasons>? fundamentalReasons,
            String? primaryReason,
            String? reasoningSummary,
            int? confidenceLevel,
            List<String>? supportingIndicators,
            List<String>? conflictingIndicators,
            String? exitPrimaryReason,
            String? exitReasoningSummary,
            int? exitConfidenceLevel,
            List<String>? exitSupportingIndicators,
            List<String>? exitConflictingIndicators,
            int? exitQualityScore,
            String? strategy)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeEntryExitReasoning():
        return $default(
            _that.technicalReasons,
            _that.fundamentalReasons,
            _that.primaryReason,
            _that.reasoningSummary,
            _that.confidenceLevel,
            _that.supportingIndicators,
            _that.conflictingIndicators,
            _that.exitPrimaryReason,
            _that.exitReasoningSummary,
            _that.exitConfidenceLevel,
            _that.exitSupportingIndicators,
            _that.exitConflictingIndicators,
            _that.exitQualityScore,
            _that.strategy);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<TechnicalReasons>? technicalReasons,
            List<FundamentalReasons>? fundamentalReasons,
            String? primaryReason,
            String? reasoningSummary,
            int? confidenceLevel,
            List<String>? supportingIndicators,
            List<String>? conflictingIndicators,
            String? exitPrimaryReason,
            String? exitReasoningSummary,
            int? exitConfidenceLevel,
            List<String>? exitSupportingIndicators,
            List<String>? exitConflictingIndicators,
            int? exitQualityScore,
            String? strategy)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeEntryExitReasoning() when $default != null:
        return $default(
            _that.technicalReasons,
            _that.fundamentalReasons,
            _that.primaryReason,
            _that.reasoningSummary,
            _that.confidenceLevel,
            _that.supportingIndicators,
            _that.conflictingIndicators,
            _that.exitPrimaryReason,
            _that.exitReasoningSummary,
            _that.exitConfidenceLevel,
            _that.exitSupportingIndicators,
            _that.exitConflictingIndicators,
            _that.exitQualityScore,
            _that.strategy);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TradeEntryExitReasoning implements TradeEntryExitReasoning {
  const _TradeEntryExitReasoning(
      {final List<TechnicalReasons>? technicalReasons,
      final List<FundamentalReasons>? fundamentalReasons,
      this.primaryReason,
      this.reasoningSummary,
      this.confidenceLevel,
      final List<String>? supportingIndicators,
      final List<String>? conflictingIndicators,
      this.exitPrimaryReason,
      this.exitReasoningSummary,
      this.exitConfidenceLevel,
      final List<String>? exitSupportingIndicators,
      final List<String>? exitConflictingIndicators,
      this.exitQualityScore,
      this.strategy})
      : _technicalReasons = technicalReasons,
        _fundamentalReasons = fundamentalReasons,
        _supportingIndicators = supportingIndicators,
        _conflictingIndicators = conflictingIndicators,
        _exitSupportingIndicators = exitSupportingIndicators,
        _exitConflictingIndicators = exitConflictingIndicators;

  final List<TechnicalReasons>? _technicalReasons;
  @override
  List<TechnicalReasons>? get technicalReasons {
    final value = _technicalReasons;
    if (value == null) return null;
    if (_technicalReasons is EqualUnmodifiableListView)
      return _technicalReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<FundamentalReasons>? _fundamentalReasons;
  @override
  List<FundamentalReasons>? get fundamentalReasons {
    final value = _fundamentalReasons;
    if (value == null) return null;
    if (_fundamentalReasons is EqualUnmodifiableListView)
      return _fundamentalReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? primaryReason;
  @override
  final String? reasoningSummary;
  @override
  final int? confidenceLevel;
  final List<String>? _supportingIndicators;
  @override
  List<String>? get supportingIndicators {
    final value = _supportingIndicators;
    if (value == null) return null;
    if (_supportingIndicators is EqualUnmodifiableListView)
      return _supportingIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _conflictingIndicators;
  @override
  List<String>? get conflictingIndicators {
    final value = _conflictingIndicators;
    if (value == null) return null;
    if (_conflictingIndicators is EqualUnmodifiableListView)
      return _conflictingIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? exitPrimaryReason;
  @override
  final String? exitReasoningSummary;
  @override
  final int? exitConfidenceLevel;
  final List<String>? _exitSupportingIndicators;
  @override
  List<String>? get exitSupportingIndicators {
    final value = _exitSupportingIndicators;
    if (value == null) return null;
    if (_exitSupportingIndicators is EqualUnmodifiableListView)
      return _exitSupportingIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _exitConflictingIndicators;
  @override
  List<String>? get exitConflictingIndicators {
    final value = _exitConflictingIndicators;
    if (value == null) return null;
    if (_exitConflictingIndicators is EqualUnmodifiableListView)
      return _exitConflictingIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? exitQualityScore;
  @override
  final String? strategy;

  /// Create a copy of TradeEntryExitReasoning
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TradeEntryExitReasoningCopyWith<_TradeEntryExitReasoning> get copyWith =>
      __$TradeEntryExitReasoningCopyWithImpl<_TradeEntryExitReasoning>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TradeEntryExitReasoning &&
            const DeepCollectionEquality()
                .equals(other._technicalReasons, _technicalReasons) &&
            const DeepCollectionEquality()
                .equals(other._fundamentalReasons, _fundamentalReasons) &&
            (identical(other.primaryReason, primaryReason) ||
                other.primaryReason == primaryReason) &&
            (identical(other.reasoningSummary, reasoningSummary) ||
                other.reasoningSummary == reasoningSummary) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel) &&
            const DeepCollectionEquality()
                .equals(other._supportingIndicators, _supportingIndicators) &&
            const DeepCollectionEquality()
                .equals(other._conflictingIndicators, _conflictingIndicators) &&
            (identical(other.exitPrimaryReason, exitPrimaryReason) ||
                other.exitPrimaryReason == exitPrimaryReason) &&
            (identical(other.exitReasoningSummary, exitReasoningSummary) ||
                other.exitReasoningSummary == exitReasoningSummary) &&
            (identical(other.exitConfidenceLevel, exitConfidenceLevel) ||
                other.exitConfidenceLevel == exitConfidenceLevel) &&
            const DeepCollectionEquality().equals(
                other._exitSupportingIndicators, _exitSupportingIndicators) &&
            const DeepCollectionEquality().equals(
                other._exitConflictingIndicators, _exitConflictingIndicators) &&
            (identical(other.exitQualityScore, exitQualityScore) ||
                other.exitQualityScore == exitQualityScore) &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_technicalReasons),
      const DeepCollectionEquality().hash(_fundamentalReasons),
      primaryReason,
      reasoningSummary,
      confidenceLevel,
      const DeepCollectionEquality().hash(_supportingIndicators),
      const DeepCollectionEquality().hash(_conflictingIndicators),
      exitPrimaryReason,
      exitReasoningSummary,
      exitConfidenceLevel,
      const DeepCollectionEquality().hash(_exitSupportingIndicators),
      const DeepCollectionEquality().hash(_exitConflictingIndicators),
      exitQualityScore,
      strategy);

  @override
  String toString() {
    return 'TradeEntryExitReasoning(technicalReasons: $technicalReasons, fundamentalReasons: $fundamentalReasons, primaryReason: $primaryReason, reasoningSummary: $reasoningSummary, confidenceLevel: $confidenceLevel, supportingIndicators: $supportingIndicators, conflictingIndicators: $conflictingIndicators, exitPrimaryReason: $exitPrimaryReason, exitReasoningSummary: $exitReasoningSummary, exitConfidenceLevel: $exitConfidenceLevel, exitSupportingIndicators: $exitSupportingIndicators, exitConflictingIndicators: $exitConflictingIndicators, exitQualityScore: $exitQualityScore, strategy: $strategy)';
  }
}

/// @nodoc
abstract mixin class _$TradeEntryExitReasoningCopyWith<$Res>
    implements $TradeEntryExitReasoningCopyWith<$Res> {
  factory _$TradeEntryExitReasoningCopyWith(_TradeEntryExitReasoning value,
          $Res Function(_TradeEntryExitReasoning) _then) =
      __$TradeEntryExitReasoningCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<TechnicalReasons>? technicalReasons,
      List<FundamentalReasons>? fundamentalReasons,
      String? primaryReason,
      String? reasoningSummary,
      int? confidenceLevel,
      List<String>? supportingIndicators,
      List<String>? conflictingIndicators,
      String? exitPrimaryReason,
      String? exitReasoningSummary,
      int? exitConfidenceLevel,
      List<String>? exitSupportingIndicators,
      List<String>? exitConflictingIndicators,
      int? exitQualityScore,
      String? strategy});
}

/// @nodoc
class __$TradeEntryExitReasoningCopyWithImpl<$Res>
    implements _$TradeEntryExitReasoningCopyWith<$Res> {
  __$TradeEntryExitReasoningCopyWithImpl(this._self, this._then);

  final _TradeEntryExitReasoning _self;
  final $Res Function(_TradeEntryExitReasoning) _then;

  /// Create a copy of TradeEntryExitReasoning
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? technicalReasons = freezed,
    Object? fundamentalReasons = freezed,
    Object? primaryReason = freezed,
    Object? reasoningSummary = freezed,
    Object? confidenceLevel = freezed,
    Object? supportingIndicators = freezed,
    Object? conflictingIndicators = freezed,
    Object? exitPrimaryReason = freezed,
    Object? exitReasoningSummary = freezed,
    Object? exitConfidenceLevel = freezed,
    Object? exitSupportingIndicators = freezed,
    Object? exitConflictingIndicators = freezed,
    Object? exitQualityScore = freezed,
    Object? strategy = freezed,
  }) {
    return _then(_TradeEntryExitReasoning(
      technicalReasons: freezed == technicalReasons
          ? _self._technicalReasons
          : technicalReasons // ignore: cast_nullable_to_non_nullable
              as List<TechnicalReasons>?,
      fundamentalReasons: freezed == fundamentalReasons
          ? _self._fundamentalReasons
          : fundamentalReasons // ignore: cast_nullable_to_non_nullable
              as List<FundamentalReasons>?,
      primaryReason: freezed == primaryReason
          ? _self.primaryReason
          : primaryReason // ignore: cast_nullable_to_non_nullable
              as String?,
      reasoningSummary: freezed == reasoningSummary
          ? _self.reasoningSummary
          : reasoningSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      confidenceLevel: freezed == confidenceLevel
          ? _self.confidenceLevel
          : confidenceLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      supportingIndicators: freezed == supportingIndicators
          ? _self._supportingIndicators
          : supportingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      conflictingIndicators: freezed == conflictingIndicators
          ? _self._conflictingIndicators
          : conflictingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitPrimaryReason: freezed == exitPrimaryReason
          ? _self.exitPrimaryReason
          : exitPrimaryReason // ignore: cast_nullable_to_non_nullable
              as String?,
      exitReasoningSummary: freezed == exitReasoningSummary
          ? _self.exitReasoningSummary
          : exitReasoningSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      exitConfidenceLevel: freezed == exitConfidenceLevel
          ? _self.exitConfidenceLevel
          : exitConfidenceLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      exitSupportingIndicators: freezed == exitSupportingIndicators
          ? _self._exitSupportingIndicators
          : exitSupportingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitConflictingIndicators: freezed == exitConflictingIndicators
          ? _self._exitConflictingIndicators
          : exitConflictingIndicators // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitQualityScore: freezed == exitQualityScore
          ? _self.exitQualityScore
          : exitQualityScore // ignore: cast_nullable_to_non_nullable
              as int?,
      strategy: freezed == strategy
          ? _self.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$BasicInfo {
  String? get tradeId;
  String? get orderId;
  DateTime? get tradeDate;
  DateTime? get orderExecutionTime;
  BrokerTypes? get brokerType;
  TradeDirections? get tradeType;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BasicInfoCopyWith<BasicInfo> get copyWith =>
      _$BasicInfoCopyWithImpl<BasicInfo>(this as BasicInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BasicInfo &&
            (identical(other.tradeId, tradeId) || other.tradeId == tradeId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.tradeDate, tradeDate) ||
                other.tradeDate == tradeDate) &&
            (identical(other.orderExecutionTime, orderExecutionTime) ||
                other.orderExecutionTime == orderExecutionTime) &&
            (identical(other.brokerType, brokerType) ||
                other.brokerType == brokerType) &&
            (identical(other.tradeType, tradeType) ||
                other.tradeType == tradeType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tradeId, orderId, tradeDate,
      orderExecutionTime, brokerType, tradeType);

  @override
  String toString() {
    return 'BasicInfo(tradeId: $tradeId, orderId: $orderId, tradeDate: $tradeDate, orderExecutionTime: $orderExecutionTime, brokerType: $brokerType, tradeType: $tradeType)';
  }
}

/// @nodoc
abstract mixin class $BasicInfoCopyWith<$Res> {
  factory $BasicInfoCopyWith(BasicInfo value, $Res Function(BasicInfo) _then) =
      _$BasicInfoCopyWithImpl;
  @useResult
  $Res call(
      {String? tradeId,
      String? orderId,
      DateTime? tradeDate,
      DateTime? orderExecutionTime,
      BrokerTypes? brokerType,
      TradeDirections? tradeType});
}

/// @nodoc
class _$BasicInfoCopyWithImpl<$Res> implements $BasicInfoCopyWith<$Res> {
  _$BasicInfoCopyWithImpl(this._self, this._then);

  final BasicInfo _self;
  final $Res Function(BasicInfo) _then;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tradeId = freezed,
    Object? orderId = freezed,
    Object? tradeDate = freezed,
    Object? orderExecutionTime = freezed,
    Object? brokerType = freezed,
    Object? tradeType = freezed,
  }) {
    return _then(_self.copyWith(
      tradeId: freezed == tradeId
          ? _self.tradeId
          : tradeId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderId: freezed == orderId
          ? _self.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      tradeDate: freezed == tradeDate
          ? _self.tradeDate
          : tradeDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orderExecutionTime: freezed == orderExecutionTime
          ? _self.orderExecutionTime
          : orderExecutionTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      brokerType: freezed == brokerType
          ? _self.brokerType
          : brokerType // ignore: cast_nullable_to_non_nullable
              as BrokerTypes?,
      tradeType: freezed == tradeType
          ? _self.tradeType
          : tradeType // ignore: cast_nullable_to_non_nullable
              as TradeDirections?,
    ));
  }
}

/// Adds pattern-matching-related methods to [BasicInfo].
extension BasicInfoPatterns on BasicInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BasicInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BasicInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BasicInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BasicInfo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BasicInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BasicInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String? tradeId,
            String? orderId,
            DateTime? tradeDate,
            DateTime? orderExecutionTime,
            BrokerTypes? brokerType,
            TradeDirections? tradeType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BasicInfo() when $default != null:
        return $default(_that.tradeId, _that.orderId, _that.tradeDate,
            _that.orderExecutionTime, _that.brokerType, _that.tradeType);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String? tradeId,
            String? orderId,
            DateTime? tradeDate,
            DateTime? orderExecutionTime,
            BrokerTypes? brokerType,
            TradeDirections? tradeType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BasicInfo():
        return $default(_that.tradeId, _that.orderId, _that.tradeDate,
            _that.orderExecutionTime, _that.brokerType, _that.tradeType);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String? tradeId,
            String? orderId,
            DateTime? tradeDate,
            DateTime? orderExecutionTime,
            BrokerTypes? brokerType,
            TradeDirections? tradeType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BasicInfo() when $default != null:
        return $default(_that.tradeId, _that.orderId, _that.tradeDate,
            _that.orderExecutionTime, _that.brokerType, _that.tradeType);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BasicInfo implements BasicInfo {
  const _BasicInfo(
      {this.tradeId,
      this.orderId,
      this.tradeDate,
      this.orderExecutionTime,
      this.brokerType,
      this.tradeType});

  @override
  final String? tradeId;
  @override
  final String? orderId;
  @override
  final DateTime? tradeDate;
  @override
  final DateTime? orderExecutionTime;
  @override
  final BrokerTypes? brokerType;
  @override
  final TradeDirections? tradeType;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BasicInfoCopyWith<_BasicInfo> get copyWith =>
      __$BasicInfoCopyWithImpl<_BasicInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BasicInfo &&
            (identical(other.tradeId, tradeId) || other.tradeId == tradeId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.tradeDate, tradeDate) ||
                other.tradeDate == tradeDate) &&
            (identical(other.orderExecutionTime, orderExecutionTime) ||
                other.orderExecutionTime == orderExecutionTime) &&
            (identical(other.brokerType, brokerType) ||
                other.brokerType == brokerType) &&
            (identical(other.tradeType, tradeType) ||
                other.tradeType == tradeType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tradeId, orderId, tradeDate,
      orderExecutionTime, brokerType, tradeType);

  @override
  String toString() {
    return 'BasicInfo(tradeId: $tradeId, orderId: $orderId, tradeDate: $tradeDate, orderExecutionTime: $orderExecutionTime, brokerType: $brokerType, tradeType: $tradeType)';
  }
}

/// @nodoc
abstract mixin class _$BasicInfoCopyWith<$Res>
    implements $BasicInfoCopyWith<$Res> {
  factory _$BasicInfoCopyWith(
          _BasicInfo value, $Res Function(_BasicInfo) _then) =
      __$BasicInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? tradeId,
      String? orderId,
      DateTime? tradeDate,
      DateTime? orderExecutionTime,
      BrokerTypes? brokerType,
      TradeDirections? tradeType});
}

/// @nodoc
class __$BasicInfoCopyWithImpl<$Res> implements _$BasicInfoCopyWith<$Res> {
  __$BasicInfoCopyWithImpl(this._self, this._then);

  final _BasicInfo _self;
  final $Res Function(_BasicInfo) _then;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tradeId = freezed,
    Object? orderId = freezed,
    Object? tradeDate = freezed,
    Object? orderExecutionTime = freezed,
    Object? brokerType = freezed,
    Object? tradeType = freezed,
  }) {
    return _then(_BasicInfo(
      tradeId: freezed == tradeId
          ? _self.tradeId
          : tradeId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderId: freezed == orderId
          ? _self.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      tradeDate: freezed == tradeDate
          ? _self.tradeDate
          : tradeDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orderExecutionTime: freezed == orderExecutionTime
          ? _self.orderExecutionTime
          : orderExecutionTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      brokerType: freezed == brokerType
          ? _self.brokerType
          : brokerType // ignore: cast_nullable_to_non_nullable
              as BrokerTypes?,
      tradeType: freezed == tradeType
          ? _self.tradeType
          : tradeType // ignore: cast_nullable_to_non_nullable
              as TradeDirections?,
    ));
  }
}

/// @nodoc
mixin _$ExecutionInfo {
  int? get quantity;
  double? get price;
  OrderTypes? get orderType;

  /// Create a copy of ExecutionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExecutionInfoCopyWith<ExecutionInfo> get copyWith =>
      _$ExecutionInfoCopyWithImpl<ExecutionInfo>(
          this as ExecutionInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExecutionInfo &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, quantity, price, orderType);

  @override
  String toString() {
    return 'ExecutionInfo(quantity: $quantity, price: $price, orderType: $orderType)';
  }
}

/// @nodoc
abstract mixin class $ExecutionInfoCopyWith<$Res> {
  factory $ExecutionInfoCopyWith(
          ExecutionInfo value, $Res Function(ExecutionInfo) _then) =
      _$ExecutionInfoCopyWithImpl;
  @useResult
  $Res call({int? quantity, double? price, OrderTypes? orderType});
}

/// @nodoc
class _$ExecutionInfoCopyWithImpl<$Res>
    implements $ExecutionInfoCopyWith<$Res> {
  _$ExecutionInfoCopyWithImpl(this._self, this._then);

  final ExecutionInfo _self;
  final $Res Function(ExecutionInfo) _then;

  /// Create a copy of ExecutionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? quantity = freezed,
    Object? price = freezed,
    Object? orderType = freezed,
  }) {
    return _then(_self.copyWith(
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int?,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      orderType: freezed == orderType
          ? _self.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as OrderTypes?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExecutionInfo].
extension ExecutionInfoPatterns on ExecutionInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ExecutionInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExecutionInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ExecutionInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExecutionInfo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ExecutionInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExecutionInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int? quantity, double? price, OrderTypes? orderType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExecutionInfo() when $default != null:
        return $default(_that.quantity, _that.price, _that.orderType);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int? quantity, double? price, OrderTypes? orderType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExecutionInfo():
        return $default(_that.quantity, _that.price, _that.orderType);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int? quantity, double? price, OrderTypes? orderType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExecutionInfo() when $default != null:
        return $default(_that.quantity, _that.price, _that.orderType);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ExecutionInfo implements ExecutionInfo {
  const _ExecutionInfo({this.quantity, this.price, this.orderType});

  @override
  final int? quantity;
  @override
  final double? price;
  @override
  final OrderTypes? orderType;

  /// Create a copy of ExecutionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExecutionInfoCopyWith<_ExecutionInfo> get copyWith =>
      __$ExecutionInfoCopyWithImpl<_ExecutionInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExecutionInfo &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, quantity, price, orderType);

  @override
  String toString() {
    return 'ExecutionInfo(quantity: $quantity, price: $price, orderType: $orderType)';
  }
}

/// @nodoc
abstract mixin class _$ExecutionInfoCopyWith<$Res>
    implements $ExecutionInfoCopyWith<$Res> {
  factory _$ExecutionInfoCopyWith(
          _ExecutionInfo value, $Res Function(_ExecutionInfo) _then) =
      __$ExecutionInfoCopyWithImpl;
  @override
  @useResult
  $Res call({int? quantity, double? price, OrderTypes? orderType});
}

/// @nodoc
class __$ExecutionInfoCopyWithImpl<$Res>
    implements _$ExecutionInfoCopyWith<$Res> {
  __$ExecutionInfoCopyWithImpl(this._self, this._then);

  final _ExecutionInfo _self;
  final $Res Function(_ExecutionInfo) _then;

  /// Create a copy of ExecutionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? quantity = freezed,
    Object? price = freezed,
    Object? orderType = freezed,
  }) {
    return _then(_ExecutionInfo(
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int?,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      orderType: freezed == orderType
          ? _self.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as OrderTypes?,
    ));
  }
}

/// @nodoc
mixin _$FnOInfo {
  DateTime? get expiryDate;
  double? get strikePrice;
  OptionTypes? get optionType;

  /// Create a copy of FnOInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FnOInfoCopyWith<FnOInfo> get copyWith =>
      _$FnOInfoCopyWithImpl<FnOInfo>(this as FnOInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FnOInfo &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.strikePrice, strikePrice) ||
                other.strikePrice == strikePrice) &&
            (identical(other.optionType, optionType) ||
                other.optionType == optionType));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, expiryDate, strikePrice, optionType);

  @override
  String toString() {
    return 'FnOInfo(expiryDate: $expiryDate, strikePrice: $strikePrice, optionType: $optionType)';
  }
}

/// @nodoc
abstract mixin class $FnOInfoCopyWith<$Res> {
  factory $FnOInfoCopyWith(FnOInfo value, $Res Function(FnOInfo) _then) =
      _$FnOInfoCopyWithImpl;
  @useResult
  $Res call(
      {DateTime? expiryDate, double? strikePrice, OptionTypes? optionType});
}

/// @nodoc
class _$FnOInfoCopyWithImpl<$Res> implements $FnOInfoCopyWith<$Res> {
  _$FnOInfoCopyWithImpl(this._self, this._then);

  final FnOInfo _self;
  final $Res Function(FnOInfo) _then;

  /// Create a copy of FnOInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? expiryDate = freezed,
    Object? strikePrice = freezed,
    Object? optionType = freezed,
  }) {
    return _then(_self.copyWith(
      expiryDate: freezed == expiryDate
          ? _self.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      strikePrice: freezed == strikePrice
          ? _self.strikePrice
          : strikePrice // ignore: cast_nullable_to_non_nullable
              as double?,
      optionType: freezed == optionType
          ? _self.optionType
          : optionType // ignore: cast_nullable_to_non_nullable
              as OptionTypes?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FnOInfo].
extension FnOInfoPatterns on FnOInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FnOInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FnOInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FnOInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FnOInfo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FnOInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FnOInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            DateTime? expiryDate, double? strikePrice, OptionTypes? optionType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FnOInfo() when $default != null:
        return $default(_that.expiryDate, _that.strikePrice, _that.optionType);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            DateTime? expiryDate, double? strikePrice, OptionTypes? optionType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FnOInfo():
        return $default(_that.expiryDate, _that.strikePrice, _that.optionType);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            DateTime? expiryDate, double? strikePrice, OptionTypes? optionType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FnOInfo() when $default != null:
        return $default(_that.expiryDate, _that.strikePrice, _that.optionType);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FnOInfo implements FnOInfo {
  const _FnOInfo({this.expiryDate, this.strikePrice, this.optionType});

  @override
  final DateTime? expiryDate;
  @override
  final double? strikePrice;
  @override
  final OptionTypes? optionType;

  /// Create a copy of FnOInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FnOInfoCopyWith<_FnOInfo> get copyWith =>
      __$FnOInfoCopyWithImpl<_FnOInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FnOInfo &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.strikePrice, strikePrice) ||
                other.strikePrice == strikePrice) &&
            (identical(other.optionType, optionType) ||
                other.optionType == optionType));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, expiryDate, strikePrice, optionType);

  @override
  String toString() {
    return 'FnOInfo(expiryDate: $expiryDate, strikePrice: $strikePrice, optionType: $optionType)';
  }
}

/// @nodoc
abstract mixin class _$FnOInfoCopyWith<$Res> implements $FnOInfoCopyWith<$Res> {
  factory _$FnOInfoCopyWith(_FnOInfo value, $Res Function(_FnOInfo) _then) =
      __$FnOInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime? expiryDate, double? strikePrice, OptionTypes? optionType});
}

/// @nodoc
class __$FnOInfoCopyWithImpl<$Res> implements _$FnOInfoCopyWith<$Res> {
  __$FnOInfoCopyWithImpl(this._self, this._then);

  final _FnOInfo _self;
  final $Res Function(_FnOInfo) _then;

  /// Create a copy of FnOInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? expiryDate = freezed,
    Object? strikePrice = freezed,
    Object? optionType = freezed,
  }) {
    return _then(_FnOInfo(
      expiryDate: freezed == expiryDate
          ? _self.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      strikePrice: freezed == strikePrice
          ? _self.strikePrice
          : strikePrice // ignore: cast_nullable_to_non_nullable
              as double?,
      optionType: freezed == optionType
          ? _self.optionType
          : optionType // ignore: cast_nullable_to_non_nullable
              as OptionTypes?,
    ));
  }
}

/// @nodoc
mixin _$Charges {
  double? get brokerage;
  double? get stt;
  double? get transactionCharges;
  double? get stampDuty;
  double? get sebiCharges;
  double? get gst;
  double? get totalTaxes;

  /// Create a copy of Charges
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChargesCopyWith<Charges> get copyWith =>
      _$ChargesCopyWithImpl<Charges>(this as Charges, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Charges &&
            (identical(other.brokerage, brokerage) ||
                other.brokerage == brokerage) &&
            (identical(other.stt, stt) || other.stt == stt) &&
            (identical(other.transactionCharges, transactionCharges) ||
                other.transactionCharges == transactionCharges) &&
            (identical(other.stampDuty, stampDuty) ||
                other.stampDuty == stampDuty) &&
            (identical(other.sebiCharges, sebiCharges) ||
                other.sebiCharges == sebiCharges) &&
            (identical(other.gst, gst) || other.gst == gst) &&
            (identical(other.totalTaxes, totalTaxes) ||
                other.totalTaxes == totalTaxes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, brokerage, stt,
      transactionCharges, stampDuty, sebiCharges, gst, totalTaxes);

  @override
  String toString() {
    return 'Charges(brokerage: $brokerage, stt: $stt, transactionCharges: $transactionCharges, stampDuty: $stampDuty, sebiCharges: $sebiCharges, gst: $gst, totalTaxes: $totalTaxes)';
  }
}

/// @nodoc
abstract mixin class $ChargesCopyWith<$Res> {
  factory $ChargesCopyWith(Charges value, $Res Function(Charges) _then) =
      _$ChargesCopyWithImpl;
  @useResult
  $Res call(
      {double? brokerage,
      double? stt,
      double? transactionCharges,
      double? stampDuty,
      double? sebiCharges,
      double? gst,
      double? totalTaxes});
}

/// @nodoc
class _$ChargesCopyWithImpl<$Res> implements $ChargesCopyWith<$Res> {
  _$ChargesCopyWithImpl(this._self, this._then);

  final Charges _self;
  final $Res Function(Charges) _then;

  /// Create a copy of Charges
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brokerage = freezed,
    Object? stt = freezed,
    Object? transactionCharges = freezed,
    Object? stampDuty = freezed,
    Object? sebiCharges = freezed,
    Object? gst = freezed,
    Object? totalTaxes = freezed,
  }) {
    return _then(_self.copyWith(
      brokerage: freezed == brokerage
          ? _self.brokerage
          : brokerage // ignore: cast_nullable_to_non_nullable
              as double?,
      stt: freezed == stt
          ? _self.stt
          : stt // ignore: cast_nullable_to_non_nullable
              as double?,
      transactionCharges: freezed == transactionCharges
          ? _self.transactionCharges
          : transactionCharges // ignore: cast_nullable_to_non_nullable
              as double?,
      stampDuty: freezed == stampDuty
          ? _self.stampDuty
          : stampDuty // ignore: cast_nullable_to_non_nullable
              as double?,
      sebiCharges: freezed == sebiCharges
          ? _self.sebiCharges
          : sebiCharges // ignore: cast_nullable_to_non_nullable
              as double?,
      gst: freezed == gst
          ? _self.gst
          : gst // ignore: cast_nullable_to_non_nullable
              as double?,
      totalTaxes: freezed == totalTaxes
          ? _self.totalTaxes
          : totalTaxes // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Charges].
extension ChargesPatterns on Charges {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Charges value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Charges() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Charges value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Charges():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Charges value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Charges() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            double? brokerage,
            double? stt,
            double? transactionCharges,
            double? stampDuty,
            double? sebiCharges,
            double? gst,
            double? totalTaxes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Charges() when $default != null:
        return $default(_that.brokerage, _that.stt, _that.transactionCharges,
            _that.stampDuty, _that.sebiCharges, _that.gst, _that.totalTaxes);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            double? brokerage,
            double? stt,
            double? transactionCharges,
            double? stampDuty,
            double? sebiCharges,
            double? gst,
            double? totalTaxes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Charges():
        return $default(_that.brokerage, _that.stt, _that.transactionCharges,
            _that.stampDuty, _that.sebiCharges, _that.gst, _that.totalTaxes);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            double? brokerage,
            double? stt,
            double? transactionCharges,
            double? stampDuty,
            double? sebiCharges,
            double? gst,
            double? totalTaxes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Charges() when $default != null:
        return $default(_that.brokerage, _that.stt, _that.transactionCharges,
            _that.stampDuty, _that.sebiCharges, _that.gst, _that.totalTaxes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Charges implements Charges {
  const _Charges(
      {this.brokerage,
      this.stt,
      this.transactionCharges,
      this.stampDuty,
      this.sebiCharges,
      this.gst,
      this.totalTaxes});

  @override
  final double? brokerage;
  @override
  final double? stt;
  @override
  final double? transactionCharges;
  @override
  final double? stampDuty;
  @override
  final double? sebiCharges;
  @override
  final double? gst;
  @override
  final double? totalTaxes;

  /// Create a copy of Charges
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChargesCopyWith<_Charges> get copyWith =>
      __$ChargesCopyWithImpl<_Charges>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Charges &&
            (identical(other.brokerage, brokerage) ||
                other.brokerage == brokerage) &&
            (identical(other.stt, stt) || other.stt == stt) &&
            (identical(other.transactionCharges, transactionCharges) ||
                other.transactionCharges == transactionCharges) &&
            (identical(other.stampDuty, stampDuty) ||
                other.stampDuty == stampDuty) &&
            (identical(other.sebiCharges, sebiCharges) ||
                other.sebiCharges == sebiCharges) &&
            (identical(other.gst, gst) || other.gst == gst) &&
            (identical(other.totalTaxes, totalTaxes) ||
                other.totalTaxes == totalTaxes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, brokerage, stt,
      transactionCharges, stampDuty, sebiCharges, gst, totalTaxes);

  @override
  String toString() {
    return 'Charges(brokerage: $brokerage, stt: $stt, transactionCharges: $transactionCharges, stampDuty: $stampDuty, sebiCharges: $sebiCharges, gst: $gst, totalTaxes: $totalTaxes)';
  }
}

/// @nodoc
abstract mixin class _$ChargesCopyWith<$Res> implements $ChargesCopyWith<$Res> {
  factory _$ChargesCopyWith(_Charges value, $Res Function(_Charges) _then) =
      __$ChargesCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double? brokerage,
      double? stt,
      double? transactionCharges,
      double? stampDuty,
      double? sebiCharges,
      double? gst,
      double? totalTaxes});
}

/// @nodoc
class __$ChargesCopyWithImpl<$Res> implements _$ChargesCopyWith<$Res> {
  __$ChargesCopyWithImpl(this._self, this._then);

  final _Charges _self;
  final $Res Function(_Charges) _then;

  /// Create a copy of Charges
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? brokerage = freezed,
    Object? stt = freezed,
    Object? transactionCharges = freezed,
    Object? stampDuty = freezed,
    Object? sebiCharges = freezed,
    Object? gst = freezed,
    Object? totalTaxes = freezed,
  }) {
    return _then(_Charges(
      brokerage: freezed == brokerage
          ? _self.brokerage
          : brokerage // ignore: cast_nullable_to_non_nullable
              as double?,
      stt: freezed == stt
          ? _self.stt
          : stt // ignore: cast_nullable_to_non_nullable
              as double?,
      transactionCharges: freezed == transactionCharges
          ? _self.transactionCharges
          : transactionCharges // ignore: cast_nullable_to_non_nullable
              as double?,
      stampDuty: freezed == stampDuty
          ? _self.stampDuty
          : stampDuty // ignore: cast_nullable_to_non_nullable
              as double?,
      sebiCharges: freezed == sebiCharges
          ? _self.sebiCharges
          : sebiCharges // ignore: cast_nullable_to_non_nullable
              as double?,
      gst: freezed == gst
          ? _self.gst
          : gst // ignore: cast_nullable_to_non_nullable
              as double?,
      totalTaxes: freezed == totalTaxes
          ? _self.totalTaxes
          : totalTaxes // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
mixin _$Financials {
  double? get turnover;
  double? get netAmount;

  /// Create a copy of Financials
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FinancialsCopyWith<Financials> get copyWith =>
      _$FinancialsCopyWithImpl<Financials>(this as Financials, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Financials &&
            (identical(other.turnover, turnover) ||
                other.turnover == turnover) &&
            (identical(other.netAmount, netAmount) ||
                other.netAmount == netAmount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, turnover, netAmount);

  @override
  String toString() {
    return 'Financials(turnover: $turnover, netAmount: $netAmount)';
  }
}

/// @nodoc
abstract mixin class $FinancialsCopyWith<$Res> {
  factory $FinancialsCopyWith(
          Financials value, $Res Function(Financials) _then) =
      _$FinancialsCopyWithImpl;
  @useResult
  $Res call({double? turnover, double? netAmount});
}

/// @nodoc
class _$FinancialsCopyWithImpl<$Res> implements $FinancialsCopyWith<$Res> {
  _$FinancialsCopyWithImpl(this._self, this._then);

  final Financials _self;
  final $Res Function(Financials) _then;

  /// Create a copy of Financials
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? turnover = freezed,
    Object? netAmount = freezed,
  }) {
    return _then(_self.copyWith(
      turnover: freezed == turnover
          ? _self.turnover
          : turnover // ignore: cast_nullable_to_non_nullable
              as double?,
      netAmount: freezed == netAmount
          ? _self.netAmount
          : netAmount // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Financials].
extension FinancialsPatterns on Financials {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Financials value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Financials() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Financials value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Financials():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Financials value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Financials() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(double? turnover, double? netAmount)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Financials() when $default != null:
        return $default(_that.turnover, _that.netAmount);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(double? turnover, double? netAmount) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Financials():
        return $default(_that.turnover, _that.netAmount);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(double? turnover, double? netAmount)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Financials() when $default != null:
        return $default(_that.turnover, _that.netAmount);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Financials implements Financials {
  const _Financials({this.turnover, this.netAmount});

  @override
  final double? turnover;
  @override
  final double? netAmount;

  /// Create a copy of Financials
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FinancialsCopyWith<_Financials> get copyWith =>
      __$FinancialsCopyWithImpl<_Financials>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Financials &&
            (identical(other.turnover, turnover) ||
                other.turnover == turnover) &&
            (identical(other.netAmount, netAmount) ||
                other.netAmount == netAmount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, turnover, netAmount);

  @override
  String toString() {
    return 'Financials(turnover: $turnover, netAmount: $netAmount)';
  }
}

/// @nodoc
abstract mixin class _$FinancialsCopyWith<$Res>
    implements $FinancialsCopyWith<$Res> {
  factory _$FinancialsCopyWith(
          _Financials value, $Res Function(_Financials) _then) =
      __$FinancialsCopyWithImpl;
  @override
  @useResult
  $Res call({double? turnover, double? netAmount});
}

/// @nodoc
class __$FinancialsCopyWithImpl<$Res> implements _$FinancialsCopyWith<$Res> {
  __$FinancialsCopyWithImpl(this._self, this._then);

  final _Financials _self;
  final $Res Function(_Financials) _then;

  /// Create a copy of Financials
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? turnover = freezed,
    Object? netAmount = freezed,
  }) {
    return _then(_Financials(
      turnover: freezed == turnover
          ? _self.turnover
          : turnover // ignore: cast_nullable_to_non_nullable
              as double?,
      netAmount: freezed == netAmount
          ? _self.netAmount
          : netAmount // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
mixin _$TradeModel {
  BasicInfo? get basicInfo;
  InstrumentInfo? get instrumentInfo;
  ExecutionInfo? get executionInfo;
  FnOInfo? get fnoInfo;
  Charges? get charges;
  Financials? get financials;

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TradeModelCopyWith<TradeModel> get copyWith =>
      _$TradeModelCopyWithImpl<TradeModel>(this as TradeModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TradeModel &&
            (identical(other.basicInfo, basicInfo) ||
                other.basicInfo == basicInfo) &&
            (identical(other.instrumentInfo, instrumentInfo) ||
                other.instrumentInfo == instrumentInfo) &&
            (identical(other.executionInfo, executionInfo) ||
                other.executionInfo == executionInfo) &&
            (identical(other.fnoInfo, fnoInfo) || other.fnoInfo == fnoInfo) &&
            (identical(other.charges, charges) || other.charges == charges) &&
            (identical(other.financials, financials) ||
                other.financials == financials));
  }

  @override
  int get hashCode => Object.hash(runtimeType, basicInfo, instrumentInfo,
      executionInfo, fnoInfo, charges, financials);

  @override
  String toString() {
    return 'TradeModel(basicInfo: $basicInfo, instrumentInfo: $instrumentInfo, executionInfo: $executionInfo, fnoInfo: $fnoInfo, charges: $charges, financials: $financials)';
  }
}

/// @nodoc
abstract mixin class $TradeModelCopyWith<$Res> {
  factory $TradeModelCopyWith(
          TradeModel value, $Res Function(TradeModel) _then) =
      _$TradeModelCopyWithImpl;
  @useResult
  $Res call(
      {BasicInfo? basicInfo,
      InstrumentInfo? instrumentInfo,
      ExecutionInfo? executionInfo,
      FnOInfo? fnoInfo,
      Charges? charges,
      Financials? financials});

  $BasicInfoCopyWith<$Res>? get basicInfo;
  $InstrumentInfoCopyWith<$Res>? get instrumentInfo;
  $ExecutionInfoCopyWith<$Res>? get executionInfo;
  $FnOInfoCopyWith<$Res>? get fnoInfo;
  $ChargesCopyWith<$Res>? get charges;
  $FinancialsCopyWith<$Res>? get financials;
}

/// @nodoc
class _$TradeModelCopyWithImpl<$Res> implements $TradeModelCopyWith<$Res> {
  _$TradeModelCopyWithImpl(this._self, this._then);

  final TradeModel _self;
  final $Res Function(TradeModel) _then;

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? basicInfo = freezed,
    Object? instrumentInfo = freezed,
    Object? executionInfo = freezed,
    Object? fnoInfo = freezed,
    Object? charges = freezed,
    Object? financials = freezed,
  }) {
    return _then(_self.copyWith(
      basicInfo: freezed == basicInfo
          ? _self.basicInfo
          : basicInfo // ignore: cast_nullable_to_non_nullable
              as BasicInfo?,
      instrumentInfo: freezed == instrumentInfo
          ? _self.instrumentInfo
          : instrumentInfo // ignore: cast_nullable_to_non_nullable
              as InstrumentInfo?,
      executionInfo: freezed == executionInfo
          ? _self.executionInfo
          : executionInfo // ignore: cast_nullable_to_non_nullable
              as ExecutionInfo?,
      fnoInfo: freezed == fnoInfo
          ? _self.fnoInfo
          : fnoInfo // ignore: cast_nullable_to_non_nullable
              as FnOInfo?,
      charges: freezed == charges
          ? _self.charges
          : charges // ignore: cast_nullable_to_non_nullable
              as Charges?,
      financials: freezed == financials
          ? _self.financials
          : financials // ignore: cast_nullable_to_non_nullable
              as Financials?,
    ));
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BasicInfoCopyWith<$Res>? get basicInfo {
    if (_self.basicInfo == null) {
      return null;
    }

    return $BasicInfoCopyWith<$Res>(_self.basicInfo!, (value) {
      return _then(_self.copyWith(basicInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InstrumentInfoCopyWith<$Res>? get instrumentInfo {
    if (_self.instrumentInfo == null) {
      return null;
    }

    return $InstrumentInfoCopyWith<$Res>(_self.instrumentInfo!, (value) {
      return _then(_self.copyWith(instrumentInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExecutionInfoCopyWith<$Res>? get executionInfo {
    if (_self.executionInfo == null) {
      return null;
    }

    return $ExecutionInfoCopyWith<$Res>(_self.executionInfo!, (value) {
      return _then(_self.copyWith(executionInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FnOInfoCopyWith<$Res>? get fnoInfo {
    if (_self.fnoInfo == null) {
      return null;
    }

    return $FnOInfoCopyWith<$Res>(_self.fnoInfo!, (value) {
      return _then(_self.copyWith(fnoInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChargesCopyWith<$Res>? get charges {
    if (_self.charges == null) {
      return null;
    }

    return $ChargesCopyWith<$Res>(_self.charges!, (value) {
      return _then(_self.copyWith(charges: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FinancialsCopyWith<$Res>? get financials {
    if (_self.financials == null) {
      return null;
    }

    return $FinancialsCopyWith<$Res>(_self.financials!, (value) {
      return _then(_self.copyWith(financials: value));
    });
  }
}

/// Adds pattern-matching-related methods to [TradeModel].
extension TradeModelPatterns on TradeModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TradeModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TradeModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TradeModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            BasicInfo? basicInfo,
            InstrumentInfo? instrumentInfo,
            ExecutionInfo? executionInfo,
            FnOInfo? fnoInfo,
            Charges? charges,
            Financials? financials)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeModel() when $default != null:
        return $default(
            _that.basicInfo,
            _that.instrumentInfo,
            _that.executionInfo,
            _that.fnoInfo,
            _that.charges,
            _that.financials);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            BasicInfo? basicInfo,
            InstrumentInfo? instrumentInfo,
            ExecutionInfo? executionInfo,
            FnOInfo? fnoInfo,
            Charges? charges,
            Financials? financials)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeModel():
        return $default(
            _that.basicInfo,
            _that.instrumentInfo,
            _that.executionInfo,
            _that.fnoInfo,
            _that.charges,
            _that.financials);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            BasicInfo? basicInfo,
            InstrumentInfo? instrumentInfo,
            ExecutionInfo? executionInfo,
            FnOInfo? fnoInfo,
            Charges? charges,
            Financials? financials)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeModel() when $default != null:
        return $default(
            _that.basicInfo,
            _that.instrumentInfo,
            _that.executionInfo,
            _that.fnoInfo,
            _that.charges,
            _that.financials);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TradeModel implements TradeModel {
  const _TradeModel(
      {this.basicInfo,
      this.instrumentInfo,
      this.executionInfo,
      this.fnoInfo,
      this.charges,
      this.financials});

  @override
  final BasicInfo? basicInfo;
  @override
  final InstrumentInfo? instrumentInfo;
  @override
  final ExecutionInfo? executionInfo;
  @override
  final FnOInfo? fnoInfo;
  @override
  final Charges? charges;
  @override
  final Financials? financials;

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TradeModelCopyWith<_TradeModel> get copyWith =>
      __$TradeModelCopyWithImpl<_TradeModel>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TradeModel &&
            (identical(other.basicInfo, basicInfo) ||
                other.basicInfo == basicInfo) &&
            (identical(other.instrumentInfo, instrumentInfo) ||
                other.instrumentInfo == instrumentInfo) &&
            (identical(other.executionInfo, executionInfo) ||
                other.executionInfo == executionInfo) &&
            (identical(other.fnoInfo, fnoInfo) || other.fnoInfo == fnoInfo) &&
            (identical(other.charges, charges) || other.charges == charges) &&
            (identical(other.financials, financials) ||
                other.financials == financials));
  }

  @override
  int get hashCode => Object.hash(runtimeType, basicInfo, instrumentInfo,
      executionInfo, fnoInfo, charges, financials);

  @override
  String toString() {
    return 'TradeModel(basicInfo: $basicInfo, instrumentInfo: $instrumentInfo, executionInfo: $executionInfo, fnoInfo: $fnoInfo, charges: $charges, financials: $financials)';
  }
}

/// @nodoc
abstract mixin class _$TradeModelCopyWith<$Res>
    implements $TradeModelCopyWith<$Res> {
  factory _$TradeModelCopyWith(
          _TradeModel value, $Res Function(_TradeModel) _then) =
      __$TradeModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {BasicInfo? basicInfo,
      InstrumentInfo? instrumentInfo,
      ExecutionInfo? executionInfo,
      FnOInfo? fnoInfo,
      Charges? charges,
      Financials? financials});

  @override
  $BasicInfoCopyWith<$Res>? get basicInfo;
  @override
  $InstrumentInfoCopyWith<$Res>? get instrumentInfo;
  @override
  $ExecutionInfoCopyWith<$Res>? get executionInfo;
  @override
  $FnOInfoCopyWith<$Res>? get fnoInfo;
  @override
  $ChargesCopyWith<$Res>? get charges;
  @override
  $FinancialsCopyWith<$Res>? get financials;
}

/// @nodoc
class __$TradeModelCopyWithImpl<$Res> implements _$TradeModelCopyWith<$Res> {
  __$TradeModelCopyWithImpl(this._self, this._then);

  final _TradeModel _self;
  final $Res Function(_TradeModel) _then;

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? basicInfo = freezed,
    Object? instrumentInfo = freezed,
    Object? executionInfo = freezed,
    Object? fnoInfo = freezed,
    Object? charges = freezed,
    Object? financials = freezed,
  }) {
    return _then(_TradeModel(
      basicInfo: freezed == basicInfo
          ? _self.basicInfo
          : basicInfo // ignore: cast_nullable_to_non_nullable
              as BasicInfo?,
      instrumentInfo: freezed == instrumentInfo
          ? _self.instrumentInfo
          : instrumentInfo // ignore: cast_nullable_to_non_nullable
              as InstrumentInfo?,
      executionInfo: freezed == executionInfo
          ? _self.executionInfo
          : executionInfo // ignore: cast_nullable_to_non_nullable
              as ExecutionInfo?,
      fnoInfo: freezed == fnoInfo
          ? _self.fnoInfo
          : fnoInfo // ignore: cast_nullable_to_non_nullable
              as FnOInfo?,
      charges: freezed == charges
          ? _self.charges
          : charges // ignore: cast_nullable_to_non_nullable
              as Charges?,
      financials: freezed == financials
          ? _self.financials
          : financials // ignore: cast_nullable_to_non_nullable
              as Financials?,
    ));
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BasicInfoCopyWith<$Res>? get basicInfo {
    if (_self.basicInfo == null) {
      return null;
    }

    return $BasicInfoCopyWith<$Res>(_self.basicInfo!, (value) {
      return _then(_self.copyWith(basicInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InstrumentInfoCopyWith<$Res>? get instrumentInfo {
    if (_self.instrumentInfo == null) {
      return null;
    }

    return $InstrumentInfoCopyWith<$Res>(_self.instrumentInfo!, (value) {
      return _then(_self.copyWith(instrumentInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExecutionInfoCopyWith<$Res>? get executionInfo {
    if (_self.executionInfo == null) {
      return null;
    }

    return $ExecutionInfoCopyWith<$Res>(_self.executionInfo!, (value) {
      return _then(_self.copyWith(executionInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FnOInfoCopyWith<$Res>? get fnoInfo {
    if (_self.fnoInfo == null) {
      return null;
    }

    return $FnOInfoCopyWith<$Res>(_self.fnoInfo!, (value) {
      return _then(_self.copyWith(fnoInfo: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChargesCopyWith<$Res>? get charges {
    if (_self.charges == null) {
      return null;
    }

    return $ChargesCopyWith<$Res>(_self.charges!, (value) {
      return _then(_self.copyWith(charges: value));
    });
  }

  /// Create a copy of TradeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FinancialsCopyWith<$Res>? get financials {
    if (_self.financials == null) {
      return null;
    }

    return $FinancialsCopyWith<$Res>(_self.financials!, (value) {
      return _then(_self.copyWith(financials: value));
    });
  }
}

/// @nodoc
mixin _$TradeDetails {
  String get tradeId;
  String get portfolioId;
  InstrumentInfo get instrumentInfo;
  TradeStatuses get status;
  TradeDirections get tradePositionType;
  EntryExitInfo get entryInfo;
  String? get symbol;
  String? get strategy;
  EntryExitInfo? get exitInfo;
  double? get currentPrice;
  TradeMetrics? get metrics;
  List<TradeModel>? get tradeExecutions;
  String? get notes;
  List<String>? get tags;
  String? get userId;
  List<Attachment>? get attachments;
  TradePsychologyData? get psychologyData;
  TradeEntryExitReasoning? get entryReasoning;
  TradeEntryExitReasoning? get exitReasoning;

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TradeDetailsCopyWith<TradeDetails> get copyWith =>
      _$TradeDetailsCopyWithImpl<TradeDetails>(
          this as TradeDetails, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TradeDetails &&
            (identical(other.tradeId, tradeId) || other.tradeId == tradeId) &&
            (identical(other.portfolioId, portfolioId) ||
                other.portfolioId == portfolioId) &&
            (identical(other.instrumentInfo, instrumentInfo) ||
                other.instrumentInfo == instrumentInfo) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.tradePositionType, tradePositionType) ||
                other.tradePositionType == tradePositionType) &&
            (identical(other.entryInfo, entryInfo) ||
                other.entryInfo == entryInfo) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy) &&
            (identical(other.exitInfo, exitInfo) ||
                other.exitInfo == exitInfo) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            (identical(other.metrics, metrics) || other.metrics == metrics) &&
            const DeepCollectionEquality()
                .equals(other.tradeExecutions, tradeExecutions) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality()
                .equals(other.attachments, attachments) &&
            (identical(other.psychologyData, psychologyData) ||
                other.psychologyData == psychologyData) &&
            (identical(other.entryReasoning, entryReasoning) ||
                other.entryReasoning == entryReasoning) &&
            (identical(other.exitReasoning, exitReasoning) ||
                other.exitReasoning == exitReasoning));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        tradeId,
        portfolioId,
        instrumentInfo,
        status,
        tradePositionType,
        entryInfo,
        symbol,
        strategy,
        exitInfo,
        currentPrice,
        metrics,
        const DeepCollectionEquality().hash(tradeExecutions),
        notes,
        const DeepCollectionEquality().hash(tags),
        userId,
        const DeepCollectionEquality().hash(attachments),
        psychologyData,
        entryReasoning,
        exitReasoning
      ]);

  @override
  String toString() {
    return 'TradeDetails(tradeId: $tradeId, portfolioId: $portfolioId, instrumentInfo: $instrumentInfo, status: $status, tradePositionType: $tradePositionType, entryInfo: $entryInfo, symbol: $symbol, strategy: $strategy, exitInfo: $exitInfo, currentPrice: $currentPrice, metrics: $metrics, tradeExecutions: $tradeExecutions, notes: $notes, tags: $tags, userId: $userId, attachments: $attachments, psychologyData: $psychologyData, entryReasoning: $entryReasoning, exitReasoning: $exitReasoning)';
  }
}

/// @nodoc
abstract mixin class $TradeDetailsCopyWith<$Res> {
  factory $TradeDetailsCopyWith(
          TradeDetails value, $Res Function(TradeDetails) _then) =
      _$TradeDetailsCopyWithImpl;
  @useResult
  $Res call(
      {String tradeId,
      String portfolioId,
      InstrumentInfo instrumentInfo,
      TradeStatuses status,
      TradeDirections tradePositionType,
      EntryExitInfo entryInfo,
      String? symbol,
      String? strategy,
      EntryExitInfo? exitInfo,
      double? currentPrice,
      TradeMetrics? metrics,
      List<TradeModel>? tradeExecutions,
      String? notes,
      List<String>? tags,
      String? userId,
      List<Attachment>? attachments,
      TradePsychologyData? psychologyData,
      TradeEntryExitReasoning? entryReasoning,
      TradeEntryExitReasoning? exitReasoning});

  $InstrumentInfoCopyWith<$Res> get instrumentInfo;
  $EntryExitInfoCopyWith<$Res> get entryInfo;
  $EntryExitInfoCopyWith<$Res>? get exitInfo;
  $TradeMetricsCopyWith<$Res>? get metrics;
  $TradePsychologyDataCopyWith<$Res>? get psychologyData;
  $TradeEntryExitReasoningCopyWith<$Res>? get entryReasoning;
  $TradeEntryExitReasoningCopyWith<$Res>? get exitReasoning;
}

/// @nodoc
class _$TradeDetailsCopyWithImpl<$Res> implements $TradeDetailsCopyWith<$Res> {
  _$TradeDetailsCopyWithImpl(this._self, this._then);

  final TradeDetails _self;
  final $Res Function(TradeDetails) _then;

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tradeId = null,
    Object? portfolioId = null,
    Object? instrumentInfo = null,
    Object? status = null,
    Object? tradePositionType = null,
    Object? entryInfo = null,
    Object? symbol = freezed,
    Object? strategy = freezed,
    Object? exitInfo = freezed,
    Object? currentPrice = freezed,
    Object? metrics = freezed,
    Object? tradeExecutions = freezed,
    Object? notes = freezed,
    Object? tags = freezed,
    Object? userId = freezed,
    Object? attachments = freezed,
    Object? psychologyData = freezed,
    Object? entryReasoning = freezed,
    Object? exitReasoning = freezed,
  }) {
    return _then(_self.copyWith(
      tradeId: null == tradeId
          ? _self.tradeId
          : tradeId // ignore: cast_nullable_to_non_nullable
              as String,
      portfolioId: null == portfolioId
          ? _self.portfolioId
          : portfolioId // ignore: cast_nullable_to_non_nullable
              as String,
      instrumentInfo: null == instrumentInfo
          ? _self.instrumentInfo
          : instrumentInfo // ignore: cast_nullable_to_non_nullable
              as InstrumentInfo,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TradeStatuses,
      tradePositionType: null == tradePositionType
          ? _self.tradePositionType
          : tradePositionType // ignore: cast_nullable_to_non_nullable
              as TradeDirections,
      entryInfo: null == entryInfo
          ? _self.entryInfo
          : entryInfo // ignore: cast_nullable_to_non_nullable
              as EntryExitInfo,
      symbol: freezed == symbol
          ? _self.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String?,
      strategy: freezed == strategy
          ? _self.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as String?,
      exitInfo: freezed == exitInfo
          ? _self.exitInfo
          : exitInfo // ignore: cast_nullable_to_non_nullable
              as EntryExitInfo?,
      currentPrice: freezed == currentPrice
          ? _self.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      metrics: freezed == metrics
          ? _self.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as TradeMetrics?,
      tradeExecutions: freezed == tradeExecutions
          ? _self.tradeExecutions
          : tradeExecutions // ignore: cast_nullable_to_non_nullable
              as List<TradeModel>?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      attachments: freezed == attachments
          ? _self.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Attachment>?,
      psychologyData: freezed == psychologyData
          ? _self.psychologyData
          : psychologyData // ignore: cast_nullable_to_non_nullable
              as TradePsychologyData?,
      entryReasoning: freezed == entryReasoning
          ? _self.entryReasoning
          : entryReasoning // ignore: cast_nullable_to_non_nullable
              as TradeEntryExitReasoning?,
      exitReasoning: freezed == exitReasoning
          ? _self.exitReasoning
          : exitReasoning // ignore: cast_nullable_to_non_nullable
              as TradeEntryExitReasoning?,
    ));
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InstrumentInfoCopyWith<$Res> get instrumentInfo {
    return $InstrumentInfoCopyWith<$Res>(_self.instrumentInfo, (value) {
      return _then(_self.copyWith(instrumentInfo: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EntryExitInfoCopyWith<$Res> get entryInfo {
    return $EntryExitInfoCopyWith<$Res>(_self.entryInfo, (value) {
      return _then(_self.copyWith(entryInfo: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EntryExitInfoCopyWith<$Res>? get exitInfo {
    if (_self.exitInfo == null) {
      return null;
    }

    return $EntryExitInfoCopyWith<$Res>(_self.exitInfo!, (value) {
      return _then(_self.copyWith(exitInfo: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradeMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
      return null;
    }

    return $TradeMetricsCopyWith<$Res>(_self.metrics!, (value) {
      return _then(_self.copyWith(metrics: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradePsychologyDataCopyWith<$Res>? get psychologyData {
    if (_self.psychologyData == null) {
      return null;
    }

    return $TradePsychologyDataCopyWith<$Res>(_self.psychologyData!, (value) {
      return _then(_self.copyWith(psychologyData: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradeEntryExitReasoningCopyWith<$Res>? get entryReasoning {
    if (_self.entryReasoning == null) {
      return null;
    }

    return $TradeEntryExitReasoningCopyWith<$Res>(_self.entryReasoning!,
        (value) {
      return _then(_self.copyWith(entryReasoning: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradeEntryExitReasoningCopyWith<$Res>? get exitReasoning {
    if (_self.exitReasoning == null) {
      return null;
    }

    return $TradeEntryExitReasoningCopyWith<$Res>(_self.exitReasoning!,
        (value) {
      return _then(_self.copyWith(exitReasoning: value));
    });
  }
}

/// Adds pattern-matching-related methods to [TradeDetails].
extension TradeDetailsPatterns on TradeDetails {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TradeDetails value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeDetails() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TradeDetails value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeDetails():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TradeDetails value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeDetails() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String tradeId,
            String portfolioId,
            InstrumentInfo instrumentInfo,
            TradeStatuses status,
            TradeDirections tradePositionType,
            EntryExitInfo entryInfo,
            String? symbol,
            String? strategy,
            EntryExitInfo? exitInfo,
            double? currentPrice,
            TradeMetrics? metrics,
            List<TradeModel>? tradeExecutions,
            String? notes,
            List<String>? tags,
            String? userId,
            List<Attachment>? attachments,
            TradePsychologyData? psychologyData,
            TradeEntryExitReasoning? entryReasoning,
            TradeEntryExitReasoning? exitReasoning)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TradeDetails() when $default != null:
        return $default(
            _that.tradeId,
            _that.portfolioId,
            _that.instrumentInfo,
            _that.status,
            _that.tradePositionType,
            _that.entryInfo,
            _that.symbol,
            _that.strategy,
            _that.exitInfo,
            _that.currentPrice,
            _that.metrics,
            _that.tradeExecutions,
            _that.notes,
            _that.tags,
            _that.userId,
            _that.attachments,
            _that.psychologyData,
            _that.entryReasoning,
            _that.exitReasoning);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String tradeId,
            String portfolioId,
            InstrumentInfo instrumentInfo,
            TradeStatuses status,
            TradeDirections tradePositionType,
            EntryExitInfo entryInfo,
            String? symbol,
            String? strategy,
            EntryExitInfo? exitInfo,
            double? currentPrice,
            TradeMetrics? metrics,
            List<TradeModel>? tradeExecutions,
            String? notes,
            List<String>? tags,
            String? userId,
            List<Attachment>? attachments,
            TradePsychologyData? psychologyData,
            TradeEntryExitReasoning? entryReasoning,
            TradeEntryExitReasoning? exitReasoning)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeDetails():
        return $default(
            _that.tradeId,
            _that.portfolioId,
            _that.instrumentInfo,
            _that.status,
            _that.tradePositionType,
            _that.entryInfo,
            _that.symbol,
            _that.strategy,
            _that.exitInfo,
            _that.currentPrice,
            _that.metrics,
            _that.tradeExecutions,
            _that.notes,
            _that.tags,
            _that.userId,
            _that.attachments,
            _that.psychologyData,
            _that.entryReasoning,
            _that.exitReasoning);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String tradeId,
            String portfolioId,
            InstrumentInfo instrumentInfo,
            TradeStatuses status,
            TradeDirections tradePositionType,
            EntryExitInfo entryInfo,
            String? symbol,
            String? strategy,
            EntryExitInfo? exitInfo,
            double? currentPrice,
            TradeMetrics? metrics,
            List<TradeModel>? tradeExecutions,
            String? notes,
            List<String>? tags,
            String? userId,
            List<Attachment>? attachments,
            TradePsychologyData? psychologyData,
            TradeEntryExitReasoning? entryReasoning,
            TradeEntryExitReasoning? exitReasoning)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TradeDetails() when $default != null:
        return $default(
            _that.tradeId,
            _that.portfolioId,
            _that.instrumentInfo,
            _that.status,
            _that.tradePositionType,
            _that.entryInfo,
            _that.symbol,
            _that.strategy,
            _that.exitInfo,
            _that.currentPrice,
            _that.metrics,
            _that.tradeExecutions,
            _that.notes,
            _that.tags,
            _that.userId,
            _that.attachments,
            _that.psychologyData,
            _that.entryReasoning,
            _that.exitReasoning);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TradeDetails implements TradeDetails {
  const _TradeDetails(
      {required this.tradeId,
      required this.portfolioId,
      required this.instrumentInfo,
      required this.status,
      required this.tradePositionType,
      required this.entryInfo,
      this.symbol,
      this.strategy,
      this.exitInfo,
      this.currentPrice,
      this.metrics,
      final List<TradeModel>? tradeExecutions,
      this.notes,
      final List<String>? tags,
      this.userId,
      final List<Attachment>? attachments,
      this.psychologyData,
      this.entryReasoning,
      this.exitReasoning})
      : _tradeExecutions = tradeExecutions,
        _tags = tags,
        _attachments = attachments;

  @override
  final String tradeId;
  @override
  final String portfolioId;
  @override
  final InstrumentInfo instrumentInfo;
  @override
  final TradeStatuses status;
  @override
  final TradeDirections tradePositionType;
  @override
  final EntryExitInfo entryInfo;
  @override
  final String? symbol;
  @override
  final String? strategy;
  @override
  final EntryExitInfo? exitInfo;
  @override
  final double? currentPrice;
  @override
  final TradeMetrics? metrics;
  final List<TradeModel>? _tradeExecutions;
  @override
  List<TradeModel>? get tradeExecutions {
    final value = _tradeExecutions;
    if (value == null) return null;
    if (_tradeExecutions is EqualUnmodifiableListView) return _tradeExecutions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? notes;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? userId;
  final List<Attachment>? _attachments;
  @override
  List<Attachment>? get attachments {
    final value = _attachments;
    if (value == null) return null;
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final TradePsychologyData? psychologyData;
  @override
  final TradeEntryExitReasoning? entryReasoning;
  @override
  final TradeEntryExitReasoning? exitReasoning;

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TradeDetailsCopyWith<_TradeDetails> get copyWith =>
      __$TradeDetailsCopyWithImpl<_TradeDetails>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TradeDetails &&
            (identical(other.tradeId, tradeId) || other.tradeId == tradeId) &&
            (identical(other.portfolioId, portfolioId) ||
                other.portfolioId == portfolioId) &&
            (identical(other.instrumentInfo, instrumentInfo) ||
                other.instrumentInfo == instrumentInfo) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.tradePositionType, tradePositionType) ||
                other.tradePositionType == tradePositionType) &&
            (identical(other.entryInfo, entryInfo) ||
                other.entryInfo == entryInfo) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy) &&
            (identical(other.exitInfo, exitInfo) ||
                other.exitInfo == exitInfo) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            (identical(other.metrics, metrics) || other.metrics == metrics) &&
            const DeepCollectionEquality()
                .equals(other._tradeExecutions, _tradeExecutions) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.psychologyData, psychologyData) ||
                other.psychologyData == psychologyData) &&
            (identical(other.entryReasoning, entryReasoning) ||
                other.entryReasoning == entryReasoning) &&
            (identical(other.exitReasoning, exitReasoning) ||
                other.exitReasoning == exitReasoning));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        tradeId,
        portfolioId,
        instrumentInfo,
        status,
        tradePositionType,
        entryInfo,
        symbol,
        strategy,
        exitInfo,
        currentPrice,
        metrics,
        const DeepCollectionEquality().hash(_tradeExecutions),
        notes,
        const DeepCollectionEquality().hash(_tags),
        userId,
        const DeepCollectionEquality().hash(_attachments),
        psychologyData,
        entryReasoning,
        exitReasoning
      ]);

  @override
  String toString() {
    return 'TradeDetails(tradeId: $tradeId, portfolioId: $portfolioId, instrumentInfo: $instrumentInfo, status: $status, tradePositionType: $tradePositionType, entryInfo: $entryInfo, symbol: $symbol, strategy: $strategy, exitInfo: $exitInfo, currentPrice: $currentPrice, metrics: $metrics, tradeExecutions: $tradeExecutions, notes: $notes, tags: $tags, userId: $userId, attachments: $attachments, psychologyData: $psychologyData, entryReasoning: $entryReasoning, exitReasoning: $exitReasoning)';
  }
}

/// @nodoc
abstract mixin class _$TradeDetailsCopyWith<$Res>
    implements $TradeDetailsCopyWith<$Res> {
  factory _$TradeDetailsCopyWith(
          _TradeDetails value, $Res Function(_TradeDetails) _then) =
      __$TradeDetailsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String tradeId,
      String portfolioId,
      InstrumentInfo instrumentInfo,
      TradeStatuses status,
      TradeDirections tradePositionType,
      EntryExitInfo entryInfo,
      String? symbol,
      String? strategy,
      EntryExitInfo? exitInfo,
      double? currentPrice,
      TradeMetrics? metrics,
      List<TradeModel>? tradeExecutions,
      String? notes,
      List<String>? tags,
      String? userId,
      List<Attachment>? attachments,
      TradePsychologyData? psychologyData,
      TradeEntryExitReasoning? entryReasoning,
      TradeEntryExitReasoning? exitReasoning});

  @override
  $InstrumentInfoCopyWith<$Res> get instrumentInfo;
  @override
  $EntryExitInfoCopyWith<$Res> get entryInfo;
  @override
  $EntryExitInfoCopyWith<$Res>? get exitInfo;
  @override
  $TradeMetricsCopyWith<$Res>? get metrics;
  @override
  $TradePsychologyDataCopyWith<$Res>? get psychologyData;
  @override
  $TradeEntryExitReasoningCopyWith<$Res>? get entryReasoning;
  @override
  $TradeEntryExitReasoningCopyWith<$Res>? get exitReasoning;
}

/// @nodoc
class __$TradeDetailsCopyWithImpl<$Res>
    implements _$TradeDetailsCopyWith<$Res> {
  __$TradeDetailsCopyWithImpl(this._self, this._then);

  final _TradeDetails _self;
  final $Res Function(_TradeDetails) _then;

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tradeId = null,
    Object? portfolioId = null,
    Object? instrumentInfo = null,
    Object? status = null,
    Object? tradePositionType = null,
    Object? entryInfo = null,
    Object? symbol = freezed,
    Object? strategy = freezed,
    Object? exitInfo = freezed,
    Object? currentPrice = freezed,
    Object? metrics = freezed,
    Object? tradeExecutions = freezed,
    Object? notes = freezed,
    Object? tags = freezed,
    Object? userId = freezed,
    Object? attachments = freezed,
    Object? psychologyData = freezed,
    Object? entryReasoning = freezed,
    Object? exitReasoning = freezed,
  }) {
    return _then(_TradeDetails(
      tradeId: null == tradeId
          ? _self.tradeId
          : tradeId // ignore: cast_nullable_to_non_nullable
              as String,
      portfolioId: null == portfolioId
          ? _self.portfolioId
          : portfolioId // ignore: cast_nullable_to_non_nullable
              as String,
      instrumentInfo: null == instrumentInfo
          ? _self.instrumentInfo
          : instrumentInfo // ignore: cast_nullable_to_non_nullable
              as InstrumentInfo,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TradeStatuses,
      tradePositionType: null == tradePositionType
          ? _self.tradePositionType
          : tradePositionType // ignore: cast_nullable_to_non_nullable
              as TradeDirections,
      entryInfo: null == entryInfo
          ? _self.entryInfo
          : entryInfo // ignore: cast_nullable_to_non_nullable
              as EntryExitInfo,
      symbol: freezed == symbol
          ? _self.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String?,
      strategy: freezed == strategy
          ? _self.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as String?,
      exitInfo: freezed == exitInfo
          ? _self.exitInfo
          : exitInfo // ignore: cast_nullable_to_non_nullable
              as EntryExitInfo?,
      currentPrice: freezed == currentPrice
          ? _self.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      metrics: freezed == metrics
          ? _self.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as TradeMetrics?,
      tradeExecutions: freezed == tradeExecutions
          ? _self._tradeExecutions
          : tradeExecutions // ignore: cast_nullable_to_non_nullable
              as List<TradeModel>?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      attachments: freezed == attachments
          ? _self._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Attachment>?,
      psychologyData: freezed == psychologyData
          ? _self.psychologyData
          : psychologyData // ignore: cast_nullable_to_non_nullable
              as TradePsychologyData?,
      entryReasoning: freezed == entryReasoning
          ? _self.entryReasoning
          : entryReasoning // ignore: cast_nullable_to_non_nullable
              as TradeEntryExitReasoning?,
      exitReasoning: freezed == exitReasoning
          ? _self.exitReasoning
          : exitReasoning // ignore: cast_nullable_to_non_nullable
              as TradeEntryExitReasoning?,
    ));
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InstrumentInfoCopyWith<$Res> get instrumentInfo {
    return $InstrumentInfoCopyWith<$Res>(_self.instrumentInfo, (value) {
      return _then(_self.copyWith(instrumentInfo: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EntryExitInfoCopyWith<$Res> get entryInfo {
    return $EntryExitInfoCopyWith<$Res>(_self.entryInfo, (value) {
      return _then(_self.copyWith(entryInfo: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EntryExitInfoCopyWith<$Res>? get exitInfo {
    if (_self.exitInfo == null) {
      return null;
    }

    return $EntryExitInfoCopyWith<$Res>(_self.exitInfo!, (value) {
      return _then(_self.copyWith(exitInfo: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradeMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
      return null;
    }

    return $TradeMetricsCopyWith<$Res>(_self.metrics!, (value) {
      return _then(_self.copyWith(metrics: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradePsychologyDataCopyWith<$Res>? get psychologyData {
    if (_self.psychologyData == null) {
      return null;
    }

    return $TradePsychologyDataCopyWith<$Res>(_self.psychologyData!, (value) {
      return _then(_self.copyWith(psychologyData: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradeEntryExitReasoningCopyWith<$Res>? get entryReasoning {
    if (_self.entryReasoning == null) {
      return null;
    }

    return $TradeEntryExitReasoningCopyWith<$Res>(_self.entryReasoning!,
        (value) {
      return _then(_self.copyWith(entryReasoning: value));
    });
  }

  /// Create a copy of TradeDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TradeEntryExitReasoningCopyWith<$Res>? get exitReasoning {
    if (_self.exitReasoning == null) {
      return null;
    }

    return $TradeEntryExitReasoningCopyWith<$Res>(_self.exitReasoning!,
        (value) {
      return _then(_self.copyWith(exitReasoning: value));
    });
  }
}

/// @nodoc
mixin _$FilterSummary {
  List<String>? get portfolioIds;
  List<String>? get symbols;
  List<String>? get statuses;
  String? get dateRange;
  List<String>? get strategies;
  String? get profitLossRange;
  String? get holdingTimeRange;

  /// Create a copy of FilterSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilterSummaryCopyWith<FilterSummary> get copyWith =>
      _$FilterSummaryCopyWithImpl<FilterSummary>(
          this as FilterSummary, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilterSummary &&
            const DeepCollectionEquality()
                .equals(other.portfolioIds, portfolioIds) &&
            const DeepCollectionEquality().equals(other.symbols, symbols) &&
            const DeepCollectionEquality().equals(other.statuses, statuses) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            const DeepCollectionEquality()
                .equals(other.strategies, strategies) &&
            (identical(other.profitLossRange, profitLossRange) ||
                other.profitLossRange == profitLossRange) &&
            (identical(other.holdingTimeRange, holdingTimeRange) ||
                other.holdingTimeRange == holdingTimeRange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(portfolioIds),
      const DeepCollectionEquality().hash(symbols),
      const DeepCollectionEquality().hash(statuses),
      dateRange,
      const DeepCollectionEquality().hash(strategies),
      profitLossRange,
      holdingTimeRange);

  @override
  String toString() {
    return 'FilterSummary(portfolioIds: $portfolioIds, symbols: $symbols, statuses: $statuses, dateRange: $dateRange, strategies: $strategies, profitLossRange: $profitLossRange, holdingTimeRange: $holdingTimeRange)';
  }
}

/// @nodoc
abstract mixin class $FilterSummaryCopyWith<$Res> {
  factory $FilterSummaryCopyWith(
          FilterSummary value, $Res Function(FilterSummary) _then) =
      _$FilterSummaryCopyWithImpl;
  @useResult
  $Res call(
      {List<String>? portfolioIds,
      List<String>? symbols,
      List<String>? statuses,
      String? dateRange,
      List<String>? strategies,
      String? profitLossRange,
      String? holdingTimeRange});
}

/// @nodoc
class _$FilterSummaryCopyWithImpl<$Res>
    implements $FilterSummaryCopyWith<$Res> {
  _$FilterSummaryCopyWithImpl(this._self, this._then);

  final FilterSummary _self;
  final $Res Function(FilterSummary) _then;

  /// Create a copy of FilterSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? portfolioIds = freezed,
    Object? symbols = freezed,
    Object? statuses = freezed,
    Object? dateRange = freezed,
    Object? strategies = freezed,
    Object? profitLossRange = freezed,
    Object? holdingTimeRange = freezed,
  }) {
    return _then(_self.copyWith(
      portfolioIds: freezed == portfolioIds
          ? _self.portfolioIds
          : portfolioIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      symbols: freezed == symbols
          ? _self.symbols
          : symbols // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      statuses: freezed == statuses
          ? _self.statuses
          : statuses // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      dateRange: freezed == dateRange
          ? _self.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as String?,
      strategies: freezed == strategies
          ? _self.strategies
          : strategies // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      profitLossRange: freezed == profitLossRange
          ? _self.profitLossRange
          : profitLossRange // ignore: cast_nullable_to_non_nullable
              as String?,
      holdingTimeRange: freezed == holdingTimeRange
          ? _self.holdingTimeRange
          : holdingTimeRange // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FilterSummary].
extension FilterSummaryPatterns on FilterSummary {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FilterSummary value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterSummary() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FilterSummary value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSummary():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FilterSummary value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSummary() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<String>? portfolioIds,
            List<String>? symbols,
            List<String>? statuses,
            String? dateRange,
            List<String>? strategies,
            String? profitLossRange,
            String? holdingTimeRange)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterSummary() when $default != null:
        return $default(
            _that.portfolioIds,
            _that.symbols,
            _that.statuses,
            _that.dateRange,
            _that.strategies,
            _that.profitLossRange,
            _that.holdingTimeRange);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<String>? portfolioIds,
            List<String>? symbols,
            List<String>? statuses,
            String? dateRange,
            List<String>? strategies,
            String? profitLossRange,
            String? holdingTimeRange)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSummary():
        return $default(
            _that.portfolioIds,
            _that.symbols,
            _that.statuses,
            _that.dateRange,
            _that.strategies,
            _that.profitLossRange,
            _that.holdingTimeRange);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<String>? portfolioIds,
            List<String>? symbols,
            List<String>? statuses,
            String? dateRange,
            List<String>? strategies,
            String? profitLossRange,
            String? holdingTimeRange)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSummary() when $default != null:
        return $default(
            _that.portfolioIds,
            _that.symbols,
            _that.statuses,
            _that.dateRange,
            _that.strategies,
            _that.profitLossRange,
            _that.holdingTimeRange);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FilterSummary implements FilterSummary {
  const _FilterSummary(
      {final List<String>? portfolioIds,
      final List<String>? symbols,
      final List<String>? statuses,
      this.dateRange,
      final List<String>? strategies,
      this.profitLossRange,
      this.holdingTimeRange})
      : _portfolioIds = portfolioIds,
        _symbols = symbols,
        _statuses = statuses,
        _strategies = strategies;

  final List<String>? _portfolioIds;
  @override
  List<String>? get portfolioIds {
    final value = _portfolioIds;
    if (value == null) return null;
    if (_portfolioIds is EqualUnmodifiableListView) return _portfolioIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _symbols;
  @override
  List<String>? get symbols {
    final value = _symbols;
    if (value == null) return null;
    if (_symbols is EqualUnmodifiableListView) return _symbols;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _statuses;
  @override
  List<String>? get statuses {
    final value = _statuses;
    if (value == null) return null;
    if (_statuses is EqualUnmodifiableListView) return _statuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? dateRange;
  final List<String>? _strategies;
  @override
  List<String>? get strategies {
    final value = _strategies;
    if (value == null) return null;
    if (_strategies is EqualUnmodifiableListView) return _strategies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? profitLossRange;
  @override
  final String? holdingTimeRange;

  /// Create a copy of FilterSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FilterSummaryCopyWith<_FilterSummary> get copyWith =>
      __$FilterSummaryCopyWithImpl<_FilterSummary>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FilterSummary &&
            const DeepCollectionEquality()
                .equals(other._portfolioIds, _portfolioIds) &&
            const DeepCollectionEquality().equals(other._symbols, _symbols) &&
            const DeepCollectionEquality().equals(other._statuses, _statuses) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            const DeepCollectionEquality()
                .equals(other._strategies, _strategies) &&
            (identical(other.profitLossRange, profitLossRange) ||
                other.profitLossRange == profitLossRange) &&
            (identical(other.holdingTimeRange, holdingTimeRange) ||
                other.holdingTimeRange == holdingTimeRange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_portfolioIds),
      const DeepCollectionEquality().hash(_symbols),
      const DeepCollectionEquality().hash(_statuses),
      dateRange,
      const DeepCollectionEquality().hash(_strategies),
      profitLossRange,
      holdingTimeRange);

  @override
  String toString() {
    return 'FilterSummary(portfolioIds: $portfolioIds, symbols: $symbols, statuses: $statuses, dateRange: $dateRange, strategies: $strategies, profitLossRange: $profitLossRange, holdingTimeRange: $holdingTimeRange)';
  }
}

/// @nodoc
abstract mixin class _$FilterSummaryCopyWith<$Res>
    implements $FilterSummaryCopyWith<$Res> {
  factory _$FilterSummaryCopyWith(
          _FilterSummary value, $Res Function(_FilterSummary) _then) =
      __$FilterSummaryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<String>? portfolioIds,
      List<String>? symbols,
      List<String>? statuses,
      String? dateRange,
      List<String>? strategies,
      String? profitLossRange,
      String? holdingTimeRange});
}

/// @nodoc
class __$FilterSummaryCopyWithImpl<$Res>
    implements _$FilterSummaryCopyWith<$Res> {
  __$FilterSummaryCopyWithImpl(this._self, this._then);

  final _FilterSummary _self;
  final $Res Function(_FilterSummary) _then;

  /// Create a copy of FilterSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? portfolioIds = freezed,
    Object? symbols = freezed,
    Object? statuses = freezed,
    Object? dateRange = freezed,
    Object? strategies = freezed,
    Object? profitLossRange = freezed,
    Object? holdingTimeRange = freezed,
  }) {
    return _then(_FilterSummary(
      portfolioIds: freezed == portfolioIds
          ? _self._portfolioIds
          : portfolioIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      symbols: freezed == symbols
          ? _self._symbols
          : symbols // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      statuses: freezed == statuses
          ? _self._statuses
          : statuses // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      dateRange: freezed == dateRange
          ? _self.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as String?,
      strategies: freezed == strategies
          ? _self._strategies
          : strategies // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      profitLossRange: freezed == profitLossRange
          ? _self.profitLossRange
          : profitLossRange // ignore: cast_nullable_to_non_nullable
              as String?,
      holdingTimeRange: freezed == holdingTimeRange
          ? _self.holdingTimeRange
          : holdingTimeRange // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$FilterTradeDetailsResponse {
  List<TradeDetails>? get trades;
  int? get totalCount;
  String? get appliedFilterName;
  FilterSummary? get filterSummary;
  int? get page;
  int? get size;
  int? get totalPages;
  bool? get isFirst;
  bool? get isLast;

  /// Create a copy of FilterTradeDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilterTradeDetailsResponseCopyWith<FilterTradeDetailsResponse>
      get copyWith =>
          _$FilterTradeDetailsResponseCopyWithImpl<FilterTradeDetailsResponse>(
              this as FilterTradeDetailsResponse, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilterTradeDetailsResponse &&
            const DeepCollectionEquality().equals(other.trades, trades) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.appliedFilterName, appliedFilterName) ||
                other.appliedFilterName == appliedFilterName) &&
            (identical(other.filterSummary, filterSummary) ||
                other.filterSummary == filterSummary) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.isFirst, isFirst) || other.isFirst == isFirst) &&
            (identical(other.isLast, isLast) || other.isLast == isLast));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(trades),
      totalCount,
      appliedFilterName,
      filterSummary,
      page,
      size,
      totalPages,
      isFirst,
      isLast);

  @override
  String toString() {
    return 'FilterTradeDetailsResponse(trades: $trades, totalCount: $totalCount, appliedFilterName: $appliedFilterName, filterSummary: $filterSummary, page: $page, size: $size, totalPages: $totalPages, isFirst: $isFirst, isLast: $isLast)';
  }
}

/// @nodoc
abstract mixin class $FilterTradeDetailsResponseCopyWith<$Res> {
  factory $FilterTradeDetailsResponseCopyWith(FilterTradeDetailsResponse value,
          $Res Function(FilterTradeDetailsResponse) _then) =
      _$FilterTradeDetailsResponseCopyWithImpl;
  @useResult
  $Res call(
      {List<TradeDetails>? trades,
      int? totalCount,
      String? appliedFilterName,
      FilterSummary? filterSummary,
      int? page,
      int? size,
      int? totalPages,
      bool? isFirst,
      bool? isLast});

  $FilterSummaryCopyWith<$Res>? get filterSummary;
}

/// @nodoc
class _$FilterTradeDetailsResponseCopyWithImpl<$Res>
    implements $FilterTradeDetailsResponseCopyWith<$Res> {
  _$FilterTradeDetailsResponseCopyWithImpl(this._self, this._then);

  final FilterTradeDetailsResponse _self;
  final $Res Function(FilterTradeDetailsResponse) _then;

  /// Create a copy of FilterTradeDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trades = freezed,
    Object? totalCount = freezed,
    Object? appliedFilterName = freezed,
    Object? filterSummary = freezed,
    Object? page = freezed,
    Object? size = freezed,
    Object? totalPages = freezed,
    Object? isFirst = freezed,
    Object? isLast = freezed,
  }) {
    return _then(_self.copyWith(
      trades: freezed == trades
          ? _self.trades
          : trades // ignore: cast_nullable_to_non_nullable
              as List<TradeDetails>?,
      totalCount: freezed == totalCount
          ? _self.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      appliedFilterName: freezed == appliedFilterName
          ? _self.appliedFilterName
          : appliedFilterName // ignore: cast_nullable_to_non_nullable
              as String?,
      filterSummary: freezed == filterSummary
          ? _self.filterSummary
          : filterSummary // ignore: cast_nullable_to_non_nullable
              as FilterSummary?,
      page: freezed == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int?,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPages: freezed == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int?,
      isFirst: freezed == isFirst
          ? _self.isFirst
          : isFirst // ignore: cast_nullable_to_non_nullable
              as bool?,
      isLast: freezed == isLast
          ? _self.isLast
          : isLast // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }

  /// Create a copy of FilterTradeDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FilterSummaryCopyWith<$Res>? get filterSummary {
    if (_self.filterSummary == null) {
      return null;
    }

    return $FilterSummaryCopyWith<$Res>(_self.filterSummary!, (value) {
      return _then(_self.copyWith(filterSummary: value));
    });
  }
}

/// Adds pattern-matching-related methods to [FilterTradeDetailsResponse].
extension FilterTradeDetailsResponsePatterns on FilterTradeDetailsResponse {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FilterTradeDetailsResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterTradeDetailsResponse() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FilterTradeDetailsResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterTradeDetailsResponse():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FilterTradeDetailsResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterTradeDetailsResponse() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<TradeDetails>? trades,
            int? totalCount,
            String? appliedFilterName,
            FilterSummary? filterSummary,
            int? page,
            int? size,
            int? totalPages,
            bool? isFirst,
            bool? isLast)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterTradeDetailsResponse() when $default != null:
        return $default(
            _that.trades,
            _that.totalCount,
            _that.appliedFilterName,
            _that.filterSummary,
            _that.page,
            _that.size,
            _that.totalPages,
            _that.isFirst,
            _that.isLast);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<TradeDetails>? trades,
            int? totalCount,
            String? appliedFilterName,
            FilterSummary? filterSummary,
            int? page,
            int? size,
            int? totalPages,
            bool? isFirst,
            bool? isLast)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterTradeDetailsResponse():
        return $default(
            _that.trades,
            _that.totalCount,
            _that.appliedFilterName,
            _that.filterSummary,
            _that.page,
            _that.size,
            _that.totalPages,
            _that.isFirst,
            _that.isLast);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<TradeDetails>? trades,
            int? totalCount,
            String? appliedFilterName,
            FilterSummary? filterSummary,
            int? page,
            int? size,
            int? totalPages,
            bool? isFirst,
            bool? isLast)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterTradeDetailsResponse() when $default != null:
        return $default(
            _that.trades,
            _that.totalCount,
            _that.appliedFilterName,
            _that.filterSummary,
            _that.page,
            _that.size,
            _that.totalPages,
            _that.isFirst,
            _that.isLast);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FilterTradeDetailsResponse implements FilterTradeDetailsResponse {
  const _FilterTradeDetailsResponse(
      {final List<TradeDetails>? trades,
      this.totalCount,
      this.appliedFilterName,
      this.filterSummary,
      this.page,
      this.size,
      this.totalPages,
      this.isFirst,
      this.isLast})
      : _trades = trades;

  final List<TradeDetails>? _trades;
  @override
  List<TradeDetails>? get trades {
    final value = _trades;
    if (value == null) return null;
    if (_trades is EqualUnmodifiableListView) return _trades;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? totalCount;
  @override
  final String? appliedFilterName;
  @override
  final FilterSummary? filterSummary;
  @override
  final int? page;
  @override
  final int? size;
  @override
  final int? totalPages;
  @override
  final bool? isFirst;
  @override
  final bool? isLast;

  /// Create a copy of FilterTradeDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FilterTradeDetailsResponseCopyWith<_FilterTradeDetailsResponse>
      get copyWith => __$FilterTradeDetailsResponseCopyWithImpl<
          _FilterTradeDetailsResponse>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FilterTradeDetailsResponse &&
            const DeepCollectionEquality().equals(other._trades, _trades) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.appliedFilterName, appliedFilterName) ||
                other.appliedFilterName == appliedFilterName) &&
            (identical(other.filterSummary, filterSummary) ||
                other.filterSummary == filterSummary) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.isFirst, isFirst) || other.isFirst == isFirst) &&
            (identical(other.isLast, isLast) || other.isLast == isLast));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_trades),
      totalCount,
      appliedFilterName,
      filterSummary,
      page,
      size,
      totalPages,
      isFirst,
      isLast);

  @override
  String toString() {
    return 'FilterTradeDetailsResponse(trades: $trades, totalCount: $totalCount, appliedFilterName: $appliedFilterName, filterSummary: $filterSummary, page: $page, size: $size, totalPages: $totalPages, isFirst: $isFirst, isLast: $isLast)';
  }
}

/// @nodoc
abstract mixin class _$FilterTradeDetailsResponseCopyWith<$Res>
    implements $FilterTradeDetailsResponseCopyWith<$Res> {
  factory _$FilterTradeDetailsResponseCopyWith(
          _FilterTradeDetailsResponse value,
          $Res Function(_FilterTradeDetailsResponse) _then) =
      __$FilterTradeDetailsResponseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<TradeDetails>? trades,
      int? totalCount,
      String? appliedFilterName,
      FilterSummary? filterSummary,
      int? page,
      int? size,
      int? totalPages,
      bool? isFirst,
      bool? isLast});

  @override
  $FilterSummaryCopyWith<$Res>? get filterSummary;
}

/// @nodoc
class __$FilterTradeDetailsResponseCopyWithImpl<$Res>
    implements _$FilterTradeDetailsResponseCopyWith<$Res> {
  __$FilterTradeDetailsResponseCopyWithImpl(this._self, this._then);

  final _FilterTradeDetailsResponse _self;
  final $Res Function(_FilterTradeDetailsResponse) _then;

  /// Create a copy of FilterTradeDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? trades = freezed,
    Object? totalCount = freezed,
    Object? appliedFilterName = freezed,
    Object? filterSummary = freezed,
    Object? page = freezed,
    Object? size = freezed,
    Object? totalPages = freezed,
    Object? isFirst = freezed,
    Object? isLast = freezed,
  }) {
    return _then(_FilterTradeDetailsResponse(
      trades: freezed == trades
          ? _self._trades
          : trades // ignore: cast_nullable_to_non_nullable
              as List<TradeDetails>?,
      totalCount: freezed == totalCount
          ? _self.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      appliedFilterName: freezed == appliedFilterName
          ? _self.appliedFilterName
          : appliedFilterName // ignore: cast_nullable_to_non_nullable
              as String?,
      filterSummary: freezed == filterSummary
          ? _self.filterSummary
          : filterSummary // ignore: cast_nullable_to_non_nullable
              as FilterSummary?,
      page: freezed == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int?,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPages: freezed == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int?,
      isFirst: freezed == isFirst
          ? _self.isFirst
          : isFirst // ignore: cast_nullable_to_non_nullable
              as bool?,
      isLast: freezed == isLast
          ? _self.isLast
          : isLast // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }

  /// Create a copy of FilterTradeDetailsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FilterSummaryCopyWith<$Res>? get filterSummary {
    if (_self.filterSummary == null) {
      return null;
    }

    return $FilterSummaryCopyWith<$Res>(_self.filterSummary!, (value) {
      return _then(_self.copyWith(filterSummary: value));
    });
  }
}

/// @nodoc
mixin _$PaginatedTradeResponse {
  List<TradeDetails>? get content;
  int? get totalElements;
  int? get totalPages;
  int? get size;
  int? get number;

  /// Create a copy of PaginatedTradeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaginatedTradeResponseCopyWith<PaginatedTradeResponse> get copyWith =>
      _$PaginatedTradeResponseCopyWithImpl<PaginatedTradeResponse>(
          this as PaginatedTradeResponse, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PaginatedTradeResponse &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.totalElements, totalElements) ||
                other.totalElements == totalElements) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.number, number) || other.number == number));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(content),
      totalElements,
      totalPages,
      size,
      number);

  @override
  String toString() {
    return 'PaginatedTradeResponse(content: $content, totalElements: $totalElements, totalPages: $totalPages, size: $size, number: $number)';
  }
}

/// @nodoc
abstract mixin class $PaginatedTradeResponseCopyWith<$Res> {
  factory $PaginatedTradeResponseCopyWith(PaginatedTradeResponse value,
          $Res Function(PaginatedTradeResponse) _then) =
      _$PaginatedTradeResponseCopyWithImpl;
  @useResult
  $Res call(
      {List<TradeDetails>? content,
      int? totalElements,
      int? totalPages,
      int? size,
      int? number});
}

/// @nodoc
class _$PaginatedTradeResponseCopyWithImpl<$Res>
    implements $PaginatedTradeResponseCopyWith<$Res> {
  _$PaginatedTradeResponseCopyWithImpl(this._self, this._then);

  final PaginatedTradeResponse _self;
  final $Res Function(PaginatedTradeResponse) _then;

  /// Create a copy of PaginatedTradeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = freezed,
    Object? totalElements = freezed,
    Object? totalPages = freezed,
    Object? size = freezed,
    Object? number = freezed,
  }) {
    return _then(_self.copyWith(
      content: freezed == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as List<TradeDetails>?,
      totalElements: freezed == totalElements
          ? _self.totalElements
          : totalElements // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPages: freezed == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int?,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      number: freezed == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PaginatedTradeResponse].
extension PaginatedTradeResponsePatterns on PaginatedTradeResponse {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PaginatedTradeResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginatedTradeResponse() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PaginatedTradeResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTradeResponse():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PaginatedTradeResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTradeResponse() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(List<TradeDetails>? content, int? totalElements,
            int? totalPages, int? size, int? number)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginatedTradeResponse() when $default != null:
        return $default(_that.content, _that.totalElements, _that.totalPages,
            _that.size, _that.number);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(List<TradeDetails>? content, int? totalElements,
            int? totalPages, int? size, int? number)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTradeResponse():
        return $default(_that.content, _that.totalElements, _that.totalPages,
            _that.size, _that.number);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(List<TradeDetails>? content, int? totalElements,
            int? totalPages, int? size, int? number)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTradeResponse() when $default != null:
        return $default(_that.content, _that.totalElements, _that.totalPages,
            _that.size, _that.number);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PaginatedTradeResponse implements PaginatedTradeResponse {
  const _PaginatedTradeResponse(
      {final List<TradeDetails>? content,
      this.totalElements,
      this.totalPages,
      this.size,
      this.number})
      : _content = content;

  final List<TradeDetails>? _content;
  @override
  List<TradeDetails>? get content {
    final value = _content;
    if (value == null) return null;
    if (_content is EqualUnmodifiableListView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? totalElements;
  @override
  final int? totalPages;
  @override
  final int? size;
  @override
  final int? number;

  /// Create a copy of PaginatedTradeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaginatedTradeResponseCopyWith<_PaginatedTradeResponse> get copyWith =>
      __$PaginatedTradeResponseCopyWithImpl<_PaginatedTradeResponse>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PaginatedTradeResponse &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            (identical(other.totalElements, totalElements) ||
                other.totalElements == totalElements) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.number, number) || other.number == number));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_content),
      totalElements,
      totalPages,
      size,
      number);

  @override
  String toString() {
    return 'PaginatedTradeResponse(content: $content, totalElements: $totalElements, totalPages: $totalPages, size: $size, number: $number)';
  }
}

/// @nodoc
abstract mixin class _$PaginatedTradeResponseCopyWith<$Res>
    implements $PaginatedTradeResponseCopyWith<$Res> {
  factory _$PaginatedTradeResponseCopyWith(_PaginatedTradeResponse value,
          $Res Function(_PaginatedTradeResponse) _then) =
      __$PaginatedTradeResponseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<TradeDetails>? content,
      int? totalElements,
      int? totalPages,
      int? size,
      int? number});
}

/// @nodoc
class __$PaginatedTradeResponseCopyWithImpl<$Res>
    implements _$PaginatedTradeResponseCopyWith<$Res> {
  __$PaginatedTradeResponseCopyWithImpl(this._self, this._then);

  final _PaginatedTradeResponse _self;
  final $Res Function(_PaginatedTradeResponse) _then;

  /// Create a copy of PaginatedTradeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? content = freezed,
    Object? totalElements = freezed,
    Object? totalPages = freezed,
    Object? size = freezed,
    Object? number = freezed,
  }) {
    return _then(_PaginatedTradeResponse(
      content: freezed == content
          ? _self._content
          : content // ignore: cast_nullable_to_non_nullable
              as List<TradeDetails>?,
      totalElements: freezed == totalElements
          ? _self.totalElements
          : totalElements // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPages: freezed == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int?,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      number: freezed == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
mixin _$ErrorResponse {
  DateTime? get timestamp;
  int? get status;
  String? get error;
  String? get message;
  String? get path;
  List<String>? get details;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ErrorResponseCopyWith<ErrorResponse> get copyWith =>
      _$ErrorResponseCopyWithImpl<ErrorResponse>(
          this as ErrorResponse, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ErrorResponse &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.path, path) || other.path == path) &&
            const DeepCollectionEquality().equals(other.details, details));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, status, error,
      message, path, const DeepCollectionEquality().hash(details));

  @override
  String toString() {
    return 'ErrorResponse(timestamp: $timestamp, status: $status, error: $error, message: $message, path: $path, details: $details)';
  }
}

/// @nodoc
abstract mixin class $ErrorResponseCopyWith<$Res> {
  factory $ErrorResponseCopyWith(
          ErrorResponse value, $Res Function(ErrorResponse) _then) =
      _$ErrorResponseCopyWithImpl;
  @useResult
  $Res call(
      {DateTime? timestamp,
      int? status,
      String? error,
      String? message,
      String? path,
      List<String>? details});
}

/// @nodoc
class _$ErrorResponseCopyWithImpl<$Res>
    implements $ErrorResponseCopyWith<$Res> {
  _$ErrorResponseCopyWithImpl(this._self, this._then);

  final ErrorResponse _self;
  final $Res Function(ErrorResponse) _then;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = freezed,
    Object? status = freezed,
    Object? error = freezed,
    Object? message = freezed,
    Object? path = freezed,
    Object? details = freezed,
  }) {
    return _then(_self.copyWith(
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as int?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      path: freezed == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _self.details
          : details // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ErrorResponse].
extension ErrorResponsePatterns on ErrorResponse {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ErrorResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ErrorResponse() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ErrorResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorResponse():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ErrorResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorResponse() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(DateTime? timestamp, int? status, String? error,
            String? message, String? path, List<String>? details)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ErrorResponse() when $default != null:
        return $default(_that.timestamp, _that.status, _that.error,
            _that.message, _that.path, _that.details);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(DateTime? timestamp, int? status, String? error,
            String? message, String? path, List<String>? details)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorResponse():
        return $default(_that.timestamp, _that.status, _that.error,
            _that.message, _that.path, _that.details);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(DateTime? timestamp, int? status, String? error,
            String? message, String? path, List<String>? details)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorResponse() when $default != null:
        return $default(_that.timestamp, _that.status, _that.error,
            _that.message, _that.path, _that.details);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ErrorResponse implements ErrorResponse {
  const _ErrorResponse(
      {this.timestamp,
      this.status,
      this.error,
      this.message,
      this.path,
      final List<String>? details})
      : _details = details;

  @override
  final DateTime? timestamp;
  @override
  final int? status;
  @override
  final String? error;
  @override
  final String? message;
  @override
  final String? path;
  final List<String>? _details;
  @override
  List<String>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableListView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ErrorResponseCopyWith<_ErrorResponse> get copyWith =>
      __$ErrorResponseCopyWithImpl<_ErrorResponse>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ErrorResponse &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.path, path) || other.path == path) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, status, error,
      message, path, const DeepCollectionEquality().hash(_details));

  @override
  String toString() {
    return 'ErrorResponse(timestamp: $timestamp, status: $status, error: $error, message: $message, path: $path, details: $details)';
  }
}

/// @nodoc
abstract mixin class _$ErrorResponseCopyWith<$Res>
    implements $ErrorResponseCopyWith<$Res> {
  factory _$ErrorResponseCopyWith(
          _ErrorResponse value, $Res Function(_ErrorResponse) _then) =
      __$ErrorResponseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime? timestamp,
      int? status,
      String? error,
      String? message,
      String? path,
      List<String>? details});
}

/// @nodoc
class __$ErrorResponseCopyWithImpl<$Res>
    implements _$ErrorResponseCopyWith<$Res> {
  __$ErrorResponseCopyWithImpl(this._self, this._then);

  final _ErrorResponse _self;
  final $Res Function(_ErrorResponse) _then;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? timestamp = freezed,
    Object? status = freezed,
    Object? error = freezed,
    Object? message = freezed,
    Object? path = freezed,
    Object? details = freezed,
  }) {
    return _then(_ErrorResponse(
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as int?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      path: freezed == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _self._details
          : details // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

// dart format on
