import 'package:json_annotation/json_annotation.dart';

/// Entry psychology factors
enum EntryPsychologyFactors {
  @JsonValue('FEAR_OF_MISSING_OUT')
  fearOfMissingOut,
  @JsonValue('OVERCONFIDENCE')
  overconfidence,
  @JsonValue('REVENGE_TRADING')
  revengeTrading,
  @JsonValue('GREED')
  greed,
  @JsonValue('PATIENCE')
  patience,
  @JsonValue('DISCIPLINE')
  discipline,
  @JsonValue('DISCIPLINED')
  disciplined,
  @JsonValue('CALM_ANALYSIS')
  calmAnalysis,
  @JsonValue('EMOTIONAL_CONTROL')
  emotionalControl,
  @JsonValue('FOLLOWING_THE_PLAN')
  followingThePlan,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Converter for EntryPsychologyFactors enum
class EntryPsychologyFactorsConverter implements JsonConverter<EntryPsychologyFactors?, String?> {
  const EntryPsychologyFactorsConverter();

  @override
  EntryPsychologyFactors? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'FEAR_OF_MISSING_OUT':
      case 'FOMO':
        return EntryPsychologyFactors.fearOfMissingOut;
      case 'OVERCONFIDENCE':
      case 'OVER_CONFIDENCE':
        return EntryPsychologyFactors.overconfidence;
      case 'REVENGE_TRADING':
      case 'REVENGE':
        return EntryPsychologyFactors.revengeTrading;
      case 'GREED':
      case 'GREEDY':
        return EntryPsychologyFactors.greed;
      case 'PATIENCE':
      case 'PATIENT':
        return EntryPsychologyFactors.patience;
      case 'DISCIPLINE':
        return EntryPsychologyFactors.discipline;
      case 'DISCIPLINED':
        return EntryPsychologyFactors.disciplined;
      case 'CALM_ANALYSIS':
      case 'CALM':
        return EntryPsychologyFactors.calmAnalysis;
      case 'EMOTIONAL_CONTROL':
      case 'EMOTIONALLY_CONTROLLED':
        return EntryPsychologyFactors.emotionalControl;
      case 'FOLLOWING_THE_PLAN':
      case 'PLAN_FOLLOWING':
      case 'FOLLOWED_PLAN':
        return EntryPsychologyFactors.followingThePlan;
      default:
        return EntryPsychologyFactors.unknown;
    }
  }

  @override
  String? toJson(EntryPsychologyFactors? value) {
    if (value == null) return null;

    switch (value) {
      case EntryPsychologyFactors.fearOfMissingOut:
        return 'FEAR_OF_MISSING_OUT';
      case EntryPsychologyFactors.overconfidence:
        return 'OVERCONFIDENCE';
      case EntryPsychologyFactors.revengeTrading:
        return 'REVENGE_TRADING';
      case EntryPsychologyFactors.greed:
        return 'GREED';
      case EntryPsychologyFactors.patience:
        return 'PATIENCE';
      case EntryPsychologyFactors.discipline:
        return 'DISCIPLINE';
      case EntryPsychologyFactors.disciplined:
        return 'DISCIPLINED';
      case EntryPsychologyFactors.calmAnalysis:
        return 'CALM_ANALYSIS';
      case EntryPsychologyFactors.emotionalControl:
        return 'EMOTIONAL_CONTROL';
      case EntryPsychologyFactors.followingThePlan:
        return 'FOLLOWING_THE_PLAN';
      case EntryPsychologyFactors.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for EntryPsychologyFactors enum
extension EntryPsychologyFactorsExtension on EntryPsychologyFactors {
  String get displayName {
    switch (this) {
      case EntryPsychologyFactors.fearOfMissingOut:
        return 'Fear of Missing Out';
      case EntryPsychologyFactors.overconfidence:
        return 'Overconfidence';
      case EntryPsychologyFactors.revengeTrading:
        return 'Revenge Trading';
      case EntryPsychologyFactors.greed:
        return 'Greed';
      case EntryPsychologyFactors.patience:
        return 'Patience';
      case EntryPsychologyFactors.discipline:
        return 'Discipline';
      case EntryPsychologyFactors.disciplined:
        return 'Disciplined';
      case EntryPsychologyFactors.calmAnalysis:
        return 'Calm Analysis';
      case EntryPsychologyFactors.emotionalControl:
        return 'Emotional Control';
      case EntryPsychologyFactors.followingThePlan:
        return 'Following The Plan';
      case EntryPsychologyFactors.unknown:
        return 'Unknown';
    }
  }
}

/// Exit psychology factors
enum ExitPsychologyFactors {
  @JsonValue('FEAR')
  fear,
  @JsonValue('GREED')
  greed,
  @JsonValue('PANIC')
  panic,
  @JsonValue('TARGET_ACHIEVED')
  targetAchieved,
  @JsonValue('STOP_LOSS_HIT')
  stopLossHit,
  @JsonValue('PLAN_FOLLOWED')
  planFollowed,
  @JsonValue('EMOTIONAL_EXIT')
  emotionalExit,
  @JsonValue('RATIONAL_EXIT')
  rationalExit,
  @JsonValue('DISCIPLINE')
  discipline,
  @JsonValue('TAKING_PROFITS')
  takingProfits,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Converter for ExitPsychologyFactors enum
class ExitPsychologyFactorsConverter implements JsonConverter<ExitPsychologyFactors?, String?> {
  const ExitPsychologyFactorsConverter();

  @override
  ExitPsychologyFactors? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'FEAR':
      case 'FEARFUL':
        return ExitPsychologyFactors.fear;
      case 'GREED':
      case 'GREEDY':
        return ExitPsychologyFactors.greed;
      case 'PANIC':
      case 'PANICKED':
        return ExitPsychologyFactors.panic;
      case 'TARGET_ACHIEVED':
      case 'TARGET_HIT':
      case 'TARGET_REACHED':
        return ExitPsychologyFactors.targetAchieved;
      case 'STOP_LOSS_HIT':
      case 'STOPLOSS_HIT':
      case 'SL_HIT':
        return ExitPsychologyFactors.stopLossHit;
      case 'PLAN_FOLLOWED':
      case 'FOLLOWED_PLAN':
        return ExitPsychologyFactors.planFollowed;
      case 'EMOTIONAL_EXIT':
      case 'EMOTIONAL':
        return ExitPsychologyFactors.emotionalExit;
      case 'RATIONAL_EXIT':
      case 'RATIONAL':
        return ExitPsychologyFactors.rationalExit;
      case 'DISCIPLINE':
      case 'DISCIPLINED':
        return ExitPsychologyFactors.discipline;
      case 'TAKING_PROFITS':
      case 'PROFIT_TAKING':
      case 'BOOK_PROFIT':
        return ExitPsychologyFactors.takingProfits;
      default:
        return ExitPsychologyFactors.unknown;
    }
  }

  @override
  String? toJson(ExitPsychologyFactors? value) {
    if (value == null) return null;

    switch (value) {
      case ExitPsychologyFactors.fear:
        return 'FEAR';
      case ExitPsychologyFactors.greed:
        return 'GREED';
      case ExitPsychologyFactors.panic:
        return 'PANIC';
      case ExitPsychologyFactors.targetAchieved:
        return 'TARGET_ACHIEVED';
      case ExitPsychologyFactors.stopLossHit:
        return 'STOP_LOSS_HIT';
      case ExitPsychologyFactors.planFollowed:
        return 'PLAN_FOLLOWED';
      case ExitPsychologyFactors.emotionalExit:
        return 'EMOTIONAL_EXIT';
      case ExitPsychologyFactors.rationalExit:
        return 'RATIONAL_EXIT';
      case ExitPsychologyFactors.discipline:
        return 'DISCIPLINE';
      case ExitPsychologyFactors.takingProfits:
        return 'TAKING_PROFITS';
      case ExitPsychologyFactors.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for ExitPsychologyFactors enum
extension ExitPsychologyFactorsExtension on ExitPsychologyFactors {
  String get displayName {
    switch (this) {
      case ExitPsychologyFactors.fear:
        return 'Fear';
      case ExitPsychologyFactors.greed:
        return 'Greed';
      case ExitPsychologyFactors.panic:
        return 'Panic';
      case ExitPsychologyFactors.targetAchieved:
        return 'Target Achieved';
      case ExitPsychologyFactors.stopLossHit:
        return 'Stop Loss Hit';
      case ExitPsychologyFactors.planFollowed:
        return 'Plan Followed';
      case ExitPsychologyFactors.emotionalExit:
        return 'Emotional Exit';
      case ExitPsychologyFactors.rationalExit:
        return 'Rational Exit';
      case ExitPsychologyFactors.discipline:
        return 'Discipline';
      case ExitPsychologyFactors.takingProfits:
        return 'Taking Profits';
      case ExitPsychologyFactors.unknown:
        return 'Unknown';
    }
  }
}

/// Behavior patterns
enum BehaviorPatterns {
  @JsonValue('OVERTRADING')
  overtrading,
  @JsonValue('LOSS_AVERSION')
  lossAversion,
  @JsonValue('CONFIRMATION_BIAS')
  confirmationBias,
  @JsonValue('DISCIPLINED_TRADING')
  disciplinedTrading,
  @JsonValue('PLAN_ADHERENCE')
  planAdherence,
  @JsonValue('RULE_FOLLOWING')
  ruleFollowing,
  @JsonValue('DISCIPLINED_EXECUTION')
  disciplinedExecution,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Converter for BehaviorPatterns enum
class BehaviorPatternsConverter implements JsonConverter<BehaviorPatterns?, String?> {
  const BehaviorPatternsConverter();

  @override
  BehaviorPatterns? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'OVERTRADING':
      case 'OVER_TRADING':
        return BehaviorPatterns.overtrading;
      case 'LOSS_AVERSION':
        return BehaviorPatterns.lossAversion;
      case 'CONFIRMATION_BIAS':
        return BehaviorPatterns.confirmationBias;
      case 'DISCIPLINED_TRADING':
        return BehaviorPatterns.disciplinedTrading;
      case 'PLAN_ADHERENCE':
      case 'ADHERING_TO_PLAN':
        return BehaviorPatterns.planAdherence;
      case 'RULE_FOLLOWING':
      case 'FOLLOWING_RULES':
        return BehaviorPatterns.ruleFollowing;
      case 'DISCIPLINED_EXECUTION':
      case 'EXECUTION_DISCIPLINE':
        return BehaviorPatterns.disciplinedExecution;
      default:
        return BehaviorPatterns.unknown;
    }
  }

  @override
  String? toJson(BehaviorPatterns? value) {
    if (value == null) return null;

    switch (value) {
      case BehaviorPatterns.overtrading:
        return 'OVERTRADING';
      case BehaviorPatterns.lossAversion:
        return 'LOSS_AVERSION';
      case BehaviorPatterns.confirmationBias:
        return 'CONFIRMATION_BIAS';
      case BehaviorPatterns.disciplinedTrading:
        return 'DISCIPLINED_TRADING';
      case BehaviorPatterns.planAdherence:
        return 'PLAN_ADHERENCE';
      case BehaviorPatterns.ruleFollowing:
        return 'RULE_FOLLOWING';
      case BehaviorPatterns.disciplinedExecution:
        return 'DISCIPLINED_EXECUTION';
      case BehaviorPatterns.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for BehaviorPatterns enum
extension BehaviorPatternsExtension on BehaviorPatterns {
  String get displayName {
    switch (this) {
      case BehaviorPatterns.overtrading:
        return 'Overtrading';
      case BehaviorPatterns.lossAversion:
        return 'Loss Aversion';
      case BehaviorPatterns.confirmationBias:
        return 'Confirmation Bias';
      case BehaviorPatterns.disciplinedTrading:
        return 'Disciplined Trading';
      case BehaviorPatterns.planAdherence:
        return 'Plan Adherence';
      case BehaviorPatterns.ruleFollowing:
        return 'Rule Following';
      case BehaviorPatterns.disciplinedExecution:
        return 'Disciplined Execution';
      case BehaviorPatterns.unknown:
        return 'Unknown';
    }
  }
}

/// List converter for EntryPsychologyFactors
class EntryPsychologyFactorsListConverter implements JsonConverter<List<EntryPsychologyFactors>?, List<dynamic>?> {
  const EntryPsychologyFactorsListConverter();

  @override
  List<EntryPsychologyFactors>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    const converter = EntryPsychologyFactorsConverter();
    return json.map((e) => converter.fromJson(e as String?)).whereType<EntryPsychologyFactors>().toList();
  }

  @override
  List<dynamic>? toJson(List<EntryPsychologyFactors>? values) {
    if (values == null) return null;
    const converter = EntryPsychologyFactorsConverter();
    return values.map((e) => converter.toJson(e)).toList();
  }
}

/// List converter for ExitPsychologyFactors
class ExitPsychologyFactorsListConverter implements JsonConverter<List<ExitPsychologyFactors>?, List<dynamic>?> {
  const ExitPsychologyFactorsListConverter();

  @override
  List<ExitPsychologyFactors>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    const converter = ExitPsychologyFactorsConverter();
    return json.map((e) => converter.fromJson(e as String?)).whereType<ExitPsychologyFactors>().toList();
  }

  @override
  List<dynamic>? toJson(List<ExitPsychologyFactors>? values) {
    if (values == null) return null;
    const converter = ExitPsychologyFactorsConverter();
    return values.map((e) => converter.toJson(e)).toList();
  }
}

/// List converter for BehaviorPatterns
class BehaviorPatternsListConverter implements JsonConverter<List<BehaviorPatterns>?, List<dynamic>?> {
  const BehaviorPatternsListConverter();

  @override
  List<BehaviorPatterns>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    const converter = BehaviorPatternsConverter();
    return json.map((e) => converter.fromJson(e as String?)).whereType<BehaviorPatterns>().toList();
  }

  @override
  List<dynamic>? toJson(List<BehaviorPatterns>? values) {
    if (values == null) return null;
    const converter = BehaviorPatternsConverter();
    return values.map((e) => converter.toJson(e)).toList();
  }
}
