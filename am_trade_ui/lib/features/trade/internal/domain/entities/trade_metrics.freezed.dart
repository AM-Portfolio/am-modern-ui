// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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
  int get holdingTimeDays;
  int get holdingTimeHours;
  int get holdingTimeMinutes;
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
      int holdingTimeDays,
      int holdingTimeHours,
      int holdingTimeMinutes,
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
    Object? holdingTimeDays = null,
    Object? holdingTimeHours = null,
    Object? holdingTimeMinutes = null,
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
      holdingTimeDays: null == holdingTimeDays
          ? _self.holdingTimeDays
          : holdingTimeDays // ignore: cast_nullable_to_non_nullable
              as int,
      holdingTimeHours: null == holdingTimeHours
          ? _self.holdingTimeHours
          : holdingTimeHours // ignore: cast_nullable_to_non_nullable
              as int,
      holdingTimeMinutes: null == holdingTimeMinutes
          ? _self.holdingTimeMinutes
          : holdingTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
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
            int holdingTimeDays,
            int holdingTimeHours,
            int holdingTimeMinutes,
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
            int holdingTimeDays,
            int holdingTimeHours,
            int holdingTimeMinutes,
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
            int holdingTimeDays,
            int holdingTimeHours,
            int holdingTimeMinutes,
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
      this.holdingTimeDays = 0,
      this.holdingTimeHours = 0,
      this.holdingTimeMinutes = 0,
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
  @JsonKey()
  final int holdingTimeDays;
  @override
  @JsonKey()
  final int holdingTimeHours;
  @override
  @JsonKey()
  final int holdingTimeMinutes;
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
      int holdingTimeDays,
      int holdingTimeHours,
      int holdingTimeMinutes,
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
    Object? holdingTimeDays = null,
    Object? holdingTimeHours = null,
    Object? holdingTimeMinutes = null,
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
      holdingTimeDays: null == holdingTimeDays
          ? _self.holdingTimeDays
          : holdingTimeDays // ignore: cast_nullable_to_non_nullable
              as int,
      holdingTimeHours: null == holdingTimeHours
          ? _self.holdingTimeHours
          : holdingTimeHours // ignore: cast_nullable_to_non_nullable
              as int,
      holdingTimeMinutes: null == holdingTimeMinutes
          ? _self.holdingTimeMinutes
          : holdingTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
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

// dart format on
