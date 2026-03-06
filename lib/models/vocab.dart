class Vocab {
  final String id;
  final String word;
  final String meaning;
  final String example;
  final String? exampleTranslation;
  final double mastery;

  Vocab({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    this.exampleTranslation,
    this.mastery = 0.0,
  });

  factory Vocab.fromJson(Map<String, dynamic> json) {
    return Vocab(
      id: json['id'].toString(),
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String,
      exampleTranslation: json['example_id'] as String?,
      mastery: (json['mastery'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'example': example,
      'example_id': exampleTranslation,
      'mastery': mastery,
    };
  }
}
