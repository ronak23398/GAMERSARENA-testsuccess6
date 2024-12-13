class TeamModel {
  String? teamId;
  String name;
  String tag;
  String owner;
  String username;
  Map<String, dynamic> members;
  Map<String, dynamic>? invitations;
  List<dynamic>? matchHistory;

  TeamModel({
    this.teamId,
    required this.name,
    required this.tag,
    required this.owner,
    required this.username,
    required this.members,
    this.invitations,
    this.matchHistory,
  });

  factory TeamModel.fromJson(Map<String, dynamic>? json, String teamId) {
    if (json == null) {
      throw ArgumentError('Team data cannot be null');
    }

    return TeamModel(
      teamId: teamId,
      name: json['name'] ?? 'Unnamed Team',
      tag: json['tag'] ?? '',
      owner: json['owner'] ?? '',
      username: json['username'] ?? 'Unknown',
      members: json['members'] is Map
          ? Map<String, dynamic>.from(json['members'])
          : {},
      invitations: json['invitations'] is Map
          ? Map<String, dynamic>.from(json['invitations'] ?? {})
          : null,
      matchHistory: json['matchHistory'] is List
          ? List<dynamic>.from(json['matchHistory'] ?? [])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tag': tag,
      'owner': owner,
      'username': username,
      'members': members,
      'invitations': invitations ?? {},
      'matchHistory': matchHistory ?? []
    };
  }
}
