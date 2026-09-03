class LeaderboardUser {
  final int rank;
  final String id;
  final String name;
  final String studyProgram;
  final int points;
  final String? avatarUrl;
  final bool isCurrentUser;

  const LeaderboardUser({
    required this.rank,
    required this.id,
    required this.name,
    required this.studyProgram,
    required this.points,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      rank: json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Mahasiswa Kampus',
      studyProgram: json['study_program'] ?? json['prodi'] ?? 'Teknik Informatika',
      points: json['points'] is int ? json['points'] : int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': id,
      'name': name,
      'study_program': studyProgram,
      'points': points,
      'avatar_url': avatarUrl,
      'is_current_user': isCurrentUser,
    };
  }

  LeaderboardUser copyWith({
    int? rank,
    String? id,
    String? name,
    String? studyProgram,
    int? points,
    String? avatarUrl,
    bool? isCurrentUser,
  }) {
    return LeaderboardUser(
      rank: rank ?? this.rank,
      id: id ?? this.id,
      name: name ?? this.name,
      studyProgram: studyProgram ?? this.studyProgram,
      points: points ?? this.points,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
