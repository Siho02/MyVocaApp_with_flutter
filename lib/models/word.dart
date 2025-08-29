// lib/models/word.dart

class Word {
  final String word;
  final List<String> meaning;
  final String example;
  final String createdAt;
  final Map<String, dynamic> reviewStats;

  Word({
    required this.word,
    required this.meaning,
    required this.example,
    required this.createdAt,
    required this.reviewStats,
  });

  // JSON(Map) 데이터로부터 Word 객체를 생성하는 특별한 생성자
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      word: json['word'] ?? '',
      meaning: List<String>.from(json['meaning'] ?? []),
      example: json['example'] ?? '',
      createdAt: json['createdAt'] ?? '',
      reviewStats: json['review_stats'] ?? {},
    );
  }
}