class UserModel {
  final String uid;
  final String email;
  final String username;
  final double walletBalance;
  final List<dynamic> challenges;
  final List<dynamic> tournaments;

  // New optional team name fields
  final String? valorantTeam;
  final String? cs2Team;
  final String? bgmiTeam;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.walletBalance = 0,
    this.challenges = const [],
    this.tournaments = const [],
    this.valorantTeam,
    this.cs2Team,
    this.bgmiTeam,
  });

  // Convert UserModel to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'walletBalance': walletBalance,
      'challenges': challenges,
      'tournaments': tournaments,
      'valorantTeam': valorantTeam,
      'cs2Team': cs2Team,
      'bgmiTeam': bgmiTeam,
    };
  }

  // Create UserModel from Firebase data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      challenges: map['challenges'] ?? [],
      tournaments: map['tournaments'] ?? [],
      valorantTeam: map['valorantTeam'],
      cs2Team: map['cs2Team'],
      bgmiTeam: map['bgmiTeam'],
    );
  }
}
