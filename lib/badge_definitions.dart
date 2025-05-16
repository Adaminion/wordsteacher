// badge_definitions.dart

// Enum for badge criteria categories
enum BadgeCategory {
  typedInWords,
  goodAnswers,
  consecutiveDays,
  accountAge, // This will be calculated, not directly stored as a stat to increment
  finishedTests,
}

// Enum for badge tiers
enum BadgeTier {
  novice,
  intermediate,
  expert,
  impossible,
}

class Badge {
  final String id; // e.g., "typed_words_novice"
  final String name; // e.g., "Word Dabbler" or "Novice: Typed Words"
  final String description; // e.g., "Typed 10 words"
  final BadgeCategory category;
  final BadgeTier tier;
  final int requirement; // e.g., 10 for 10 words
  final String iconAsset; // Path to a simple icon for the badge

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    required this.requirement,
    required this.iconAsset, // e.g., 'assets/badges/typed_words_novice.png'
  });
}

// Define all your badges
const List<Badge> allBadges = [
  // Typed in Words
  Badge(id: 'typed_words_novice', name: 'Word Typer Novice', description: 'Type 10 words', category: BadgeCategory.typedInWords, tier: BadgeTier.novice, requirement: 10, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'typed_words_intermediate', name: 'Word Typer Intermediate', description: 'Type 100 words', category: BadgeCategory.typedInWords, tier: BadgeTier.intermediate, requirement: 100, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'typed_words_expert', name: 'Word Typer Expert', description: 'Type 500 words', category: BadgeCategory.typedInWords, tier: BadgeTier.expert, requirement: 500, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'typed_words_impossible', name: 'Word Typer Impossible', description: 'Type 1000 words', category: BadgeCategory.typedInWords, tier: BadgeTier.impossible, requirement: 1000, iconAsset: 'assets/badges/default.png'),

  // Good Answers
  Badge(id: 'good_answers_novice', name: 'Answer Ace Novice', description: 'Get 10 good answers', category: BadgeCategory.goodAnswers, tier: BadgeTier.novice, requirement: 10, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'good_answers_intermediate', name: 'Answer Ace Intermediate', description: 'Get 100 good answers', category: BadgeCategory.goodAnswers, tier: BadgeTier.intermediate, requirement: 100, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'good_answers_expert', name: 'Answer Ace Expert', description: 'Get 1000 good answers', category: BadgeCategory.goodAnswers, tier: BadgeTier.expert, requirement: 1000, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'good_answers_impossible', name: 'Answer Ace Impossible', description: 'Get 5000 good answers', category: BadgeCategory.goodAnswers, tier: BadgeTier.impossible, requirement: 5000, iconAsset: 'assets/badges/default.png'),

  // Consecutive Days (usage is counted when you finish a test with a positive (D or better) score)
  Badge(id: 'consecutive_days_novice', name: 'Daily Rookie', description: '3 consecutive days of usage', category: BadgeCategory.consecutiveDays, tier: BadgeTier.novice, requirement: 3, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'consecutive_days_intermediate', name: 'Daily Regular', description: '10 consecutive days of usage', category: BadgeCategory.consecutiveDays, tier: BadgeTier.intermediate, requirement: 10, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'consecutive_days_expert', name: 'Daily Devotee', description: '30 consecutive days of usage', category: BadgeCategory.consecutiveDays, tier: BadgeTier.expert, requirement: 30, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'consecutive_days_impossible', name: 'Daily Legend', description: '100 consecutive days of usage', category: BadgeCategory.consecutiveDays, tier: BadgeTier.impossible, requirement: 100, iconAsset: 'assets/badges/default.png'),

  // Account Age (Calculated)
  Badge(id: 'account_age_novice', name: 'Newcomer', description: 'Account older than 7 days', category: BadgeCategory.accountAge, tier: BadgeTier.novice, requirement: 7, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'account_age_intermediate', name: 'Established User', description: 'Account older than 30 days', category: BadgeCategory.accountAge, tier: BadgeTier.intermediate, requirement: 30, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'account_age_expert', name: 'Veteran User', description: 'Account older than 100 days', category: BadgeCategory.accountAge, tier: BadgeTier.expert, requirement: 100, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'account_age_impossible', name: 'Ancient User', description: 'Account older than 500 days', category: BadgeCategory.accountAge, tier: BadgeTier.impossible, requirement: 500, iconAsset: 'assets/badges/default.png'),

  // Number of Finished Tests (tests with at least 15 questions)
  Badge(id: 'finished_tests_novice', name: 'Test Taker Novice', description: 'Finish 3 tests', category: BadgeCategory.finishedTests, tier: BadgeTier.novice, requirement: 3, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'finished_tests_intermediate', name: 'Test Taker Intermediate', description: 'Finish 10 tests', category: BadgeCategory.finishedTests, tier: BadgeTier.intermediate, requirement: 10, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'finished_tests_expert', name: 'Test Taker Expert', description: 'Finish 100 tests', category: BadgeCategory.finishedTests, tier: BadgeTier.expert, requirement: 100, iconAsset: 'assets/badges/default.png'),
  Badge(id: 'finished_tests_impossible', name: 'Test Taker Impossible', description: 'Finish 500 tests', category: BadgeCategory.finishedTests, tier: BadgeTier.impossible, requirement: 500, iconAsset: 'assets/badges/default.png'),
];

// Helper to get badges by category and tier, and to find next badge
Map<BadgeCategory, List<Badge>> get badgesByCategory {
  final map = <BadgeCategory, List<Badge>>{};
  for (var badge in allBadges) {
    (map[badge.category] ??= []).add(badge);
  }
  // Sort by requirement within each category
  map.forEach((key, value) {
    value.sort((a, b) => a.requirement.compareTo(b.requirement));
  });
  return map;
}