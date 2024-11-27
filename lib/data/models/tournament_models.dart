import 'package:flutter/foundation.dart';

@immutable
class Tournament {
  final String id;
  final String name;
  final String game;
  final String platform;
  final double entryFee;
  final double prizePool;
  final String format;
  final String participationType;
  final int maxParticipants;
  final String status;
  final DateTime startDate;
  final DateTime registrationEndDate;
  final DateTime endDate;
  final List<String> rules;
  final Map<String, double> prizes;
  final String createdBy;
  final Map<String, dynamic>? participants;

  const Tournament({
    required this.id,
    required this.name,
    required this.game,
    required this.platform,
    required this.entryFee,
    required this.prizePool,
    required this.format,
    required this.participationType,
    required this.maxParticipants,
    required this.status,
    required this.startDate,
    required this.registrationEndDate,
    required this.endDate,
    required this.rules,
    required this.prizes,
    required this.createdBy,
    this.participants,
  });

  factory Tournament.fromJson(Map<dynamic, dynamic>? json, String id) {
    if (json == null) {
      throw ArgumentError('Tournament JSON cannot be null');
    }

    return Tournament(
      id: id,
      name: _safeGet(json, ['name'], ''),
      game: _safeGet(json, ['game'], ''),
      platform: _safeGet(json, ['platform'], ''),
      entryFee: _safeGetDouble(json, ['entryFee'], 0.0),
      prizePool: _safeGetDouble(json, ['prizePool'], 0.0),
      format: _safeGet(json, ['format'], ''),
      participationType: _safeGet(json, ['participationType'], ''),
      maxParticipants: _safeGetInt(json, ['maxParticipants'], 0),
      status: _safeGet(json, ['status'], 'Open'),
      startDate: _safeGetDateTime(json, ['startDate'], DateTime.now()),
      registrationEndDate:
          _safeGetDateTime(json, ['registrationEndDate'], DateTime.now()),
      endDate: _safeGetDateTime(json, ['endDate'], DateTime.now()),
      rules: _safeGetList(json, ['rules'], []),
      prizes: _safeGetMap(json, ['prizes'], {}),
      createdBy: _safeGet(json, ['createdBy'], ''),
    );
  }

  bool isRegistrationOpen() {
    final now = DateTime.now();
    return now.isBefore(registrationEndDate) &&
        (participants?.length ?? 0) < maxParticipants;
  }

  int getRemainingSlots() {
    return maxParticipants - (participants?.length ?? 0);
  }

  int getParticipantCount() {
    return participants?.length ?? 0;
  }

  // Utility methods for safe JSON parsing
  static dynamic _safeGet(
      Map<dynamic, dynamic> json, List<String> keys, dynamic defaultValue) {
    dynamic value = json;
    for (var key in keys) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return defaultValue;
      }
    }
    return value ?? defaultValue;
  }

  static double _safeGetDouble(
      Map<dynamic, dynamic> json, List<String> keys, double defaultValue) {
    final value = _safeGet(json, keys, null);
    return value is num ? value.toDouble() : defaultValue;
  }

  static int _safeGetInt(
      Map<dynamic, dynamic> json, List<String> keys, int defaultValue) {
    final value = _safeGet(json, keys, null);
    return value is num ? value.toInt() : defaultValue;
  }

  static DateTime _safeGetDateTime(
      Map<dynamic, dynamic> json, List<String> keys, DateTime defaultValue) {
    final value = _safeGet(json, keys, null);

    if (value == null) return defaultValue;

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  static List<String> _safeGetList(Map<dynamic, dynamic> json,
      List<String> keys, List<String> defaultValue) {
    final value = _safeGet(json, keys, null);
    return value is List ? List<String>.from(value) : defaultValue;
  }

  static Map<String, double> _safeGetMap(Map<dynamic, dynamic> json,
      List<String> keys, Map<String, double> defaultValue) {
    final value = _safeGet(json, keys, null);
    if (value is Map) {
      return Map<String, double>.from(value.map((key, val) =>
          MapEntry(key.toString(), (val is num) ? val.toDouble() : 0.0)));
    }
    return defaultValue;
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult(this.isValid, {this.errors = const []});
}

class TournamentValidator {
  static ValidationResult validate(Tournament tournament) {
    final errors = <String>[];

    // Name validation
    if (tournament.name.trim().isEmpty) {
      errors.add('Tournament name cannot be empty');
    }

    // Game validation
    if (tournament.game.trim().isEmpty) {
      errors.add('Game name cannot be empty');
    }

    // Participant validations
    if (tournament.maxParticipants <= 1) {
      errors.add('Maximum participants must be at least 2');
    }

    // Date validations
    final now = DateTime.now();

    if (tournament.registrationEndDate.isBefore(now)) {
      errors.add('Registration end date must be in the future');
    }

    if (tournament.startDate.isBefore(now)) {
      errors.add('Tournament start date must be in the future');
    }

    if (tournament.registrationEndDate.isAfter(tournament.startDate)) {
      errors.add('Registration end date must be before tournament start date');
    }

    if (tournament.startDate.isAfter(tournament.endDate)) {
      errors.add('Tournament start date must be before end date');
    }

    // Prize pool validations
    if (tournament.prizePool <= 0) {
      errors.add('Prize pool must be greater than zero');
    }

    // Entry fee validations
    if (tournament.entryFee < 0) {
      errors.add('Entry fee cannot be negative');
    }

    return ValidationResult(errors.isEmpty, errors: errors);
  }
}
