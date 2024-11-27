class Tournament {
  String id;
  String name;
  String game;
  String platform;
  double entryFee;
  double prizePool;
  String format;
  String participationType;
  int maxParticipants;
  String status;
  DateTime startDate;
  DateTime registrationEndDate;
  DateTime endDate;
  List<String> rules;
  Map<String, double> prizes;
  String createdBy;
  Map<String, dynamic>? participants; // Make participants more flexible

  Tournament({
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
    // Handle null json
    if (json == null) {
      throw ArgumentError('Tournament JSON cannot be null');
    }

    // Safe access with null checks and default values
    return Tournament(
      id: id,
      name: _safeGet(json, ['name', 'basicInfo', 'name'], ''),
      game: _safeGet(json, ['game', 'basicInfo', 'game'], ''),
      platform: _safeGet(json, ['platform', 'basicInfo', 'platform'], ''),
      entryFee:
          _safeGetDouble(json, ['entryFee', 'basicInfo', 'entryFee'], 0.0),
      prizePool:
          _safeGetDouble(json, ['prizePool', 'basicInfo', 'prizePool'], 0.0),
      format: _safeGet(json, ['format', 'basicInfo', 'format'], ''),
      participationType: _safeGet(
          json, ['participationType', 'basicInfo', 'participationType'], ''),
      maxParticipants: _safeGetInt(
          json, ['maxParticipants', 'basicInfo', 'maxParticipants'], 0),
      status: _safeGet(json, ['status', 'basicInfo', 'status'], 'Open'),
      startDate: _safeGetDateTime(
          json, ['startDate', 'dates', 'startDate'], DateTime.now()),
      registrationEndDate: _safeGetDateTime(
          json,
          ['registrationEndDate', 'dates', 'registrationEndDate'],
          DateTime.now()),
      endDate: _safeGetDateTime(
          json, ['endDate', 'dates', 'endDate'], DateTime.now()),
      rules: _safeGetList(json, ['rules', 'rulesList'], []),
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
  static dynamic _traverseJson(Map<dynamic, dynamic> json, List<String> keys) {
    dynamic value = json;
    for (var key in keys) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    return value;
  }

  static String _safeGet(
      Map<dynamic, dynamic> json, List<String> keys, String defaultValue) {
    final value = _traverseJson(json, keys);
    return value?.toString() ?? defaultValue;
  }

  static double _safeGetDouble(
      Map<dynamic, dynamic> json, List<String> keys, double defaultValue) {
    final value = _traverseJson(json, keys);
    if (value == null) return defaultValue;
    return (value is num) ? value.toDouble() : defaultValue;
  }

  static int _safeGetInt(
      Map<dynamic, dynamic> json, List<String> keys, int defaultValue) {
    final value = _traverseJson(json, keys);
    if (value == null) return defaultValue;
    return (value is num) ? value.toInt() : defaultValue;
  }

  static DateTime _safeGetDateTime(
      Map<dynamic, dynamic> json, List<String> keys, DateTime defaultValue) {
    final value = _traverseJson(json, keys);
    if (value == null) return defaultValue;

    // Handle different date formats
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  static List<String> _safeGetList(Map<dynamic, dynamic> json,
      List<String> keys, List<String> defaultValue) {
    final value = _traverseJson(json, keys);
    return value is List ? List<String>.from(value) : defaultValue;
  }

  static Map<String, double> _safeGetMap(Map<dynamic, dynamic> json,
      List<String> keys, Map<String, double> defaultValue) {
    final value = _traverseJson(json, keys);
    if (value is Map) {
      return Map<String, double>.from(value.map((key, val) =>
          MapEntry(key.toString(), (val is num) ? val.toDouble() : 0.0)));
    }
    return defaultValue;
  }

  // Existing toJson method remains the same
  Map<String, dynamic> toJson() {
    return {
      'basicInfo': {
        'name': name,
        'game': game,
        'platform': platform,
        'entryFee': entryFee,
        'prizePool': prizePool,
        'format': format,
        'participationType': participationType,
        'maxParticipants': maxParticipants,
        'status': status,
      },
      'dates': {
        'startDate': startDate.millisecondsSinceEpoch,
        'registrationEndDate': registrationEndDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      },
      'rules': {
        'rulesList': rules,
      },
      'prizes': prizes,
      'createdBy': createdBy,
    };
  }
}
