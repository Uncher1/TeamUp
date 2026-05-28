class MatchedUser {
  final int id;
  final String fullName;
  final String? email;
  final double score;
  final double skillMatch;
  final double interestMatch;

  const MatchedUser({
    required this.id,
    required this.fullName,
    this.email,
    required this.score,
    required this.skillMatch,
    required this.interestMatch,
  });

  factory MatchedUser.fromJson(Map<String, dynamic> j) => MatchedUser(
        id: j['user_id'] as int,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String?,
        score: (j['score'] as num).toDouble(),
        skillMatch: (j['skill_match'] as num).toDouble(),
        interestMatch: (j['interest_match'] as num).toDouble(),
      );
}

class MatchedProject {
  final int id;
  final String title;
  final String description;
  final double score;
  final double skillMatch;
  final double interestMatch;

  const MatchedProject({
    required this.id,
    required this.title,
    required this.description,
    required this.score,
    required this.skillMatch,
    required this.interestMatch,
  });

  factory MatchedProject.fromJson(Map<String, dynamic> j) => MatchedProject(
        id: j['project_id'] as int,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        score: (j['score'] as num).toDouble(),
        skillMatch: (j['skill_match'] as num).toDouble(),
        interestMatch: (j['interest_match'] as num).toDouble(),
      );
}
