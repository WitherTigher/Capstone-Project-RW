class Word {
  final String id;
  final String text;
  final String type; // e.g., Dolch, Phonic, MinimalPairs
  final List<String> sentences;

  Word({
    required this.id,
    required this.text,
    required this.type,
    required this.sentences,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type,
    'sentences': sentences,
  };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    id: json['id'],
    text: json['text'],
    type: json['type'],
    sentences: (json['sentences'] as List?)?.cast<String>() ?? [],
  );

  Word copyWith({
    String? id,
    String? text,
    String? type,
    List<String>? sentences,
  }) {
    return Word(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      sentences: sentences ?? this.sentences,
    );
  }
}