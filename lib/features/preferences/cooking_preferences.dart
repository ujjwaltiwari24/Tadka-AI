class CookingPreferences {
  final String time;
  final String budget;
  final int servings;
  final String diet;
  final List<String> avoid;
  final String spiceLevel;
  final String skill;

  const CookingPreferences({
    required this.time,
    required this.budget,
    required this.servings,
    required this.diet,
    required this.avoid,
    required this.spiceLevel,
    required this.skill,
  });

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'budget': budget,
      'servings': servings,
      'diet': diet,
      'avoid': avoid,
      'spiceLevel': spiceLevel,
      'skill': skill,
    };
  }
}