class LeaderboardEntry {
  final String id;
  final String playerName;
  final int score;
  final int level;
  final double time;
  final DateTime? createdAt;

  LeaderboardEntry({
    required this.id,
    required this.playerName,
    required this.score,
    required this.level,
    required this.time,
    this.createdAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['_id'] ?? json['id'] ?? '';
    final dynamic playerValue =
        json['player_name'] ?? json['playerName'] ?? json['player'] ?? '';
    final dynamic scoreValue = json['score'] ?? 0;
    final dynamic levelValue = json['level'] ?? 0;
    final dynamic timeValue = json['time'] ?? 0;
    final dynamic createdValue = json['created_at'] ?? json['createdAt'];

    return LeaderboardEntry(
      id: idValue.toString(),
      playerName: playerValue.toString(),
      score: (scoreValue as num).toInt(),
      level: (levelValue as num).toInt(),
      time: (timeValue as num).toDouble(),
      createdAt: createdValue == null
          ? null
          : DateTime.tryParse(createdValue.toString()),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'player_name': playerName,
      'score': score,
      'level': level,
      'time': time,
    };
  }
}
