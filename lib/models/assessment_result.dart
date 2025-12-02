class AssessmentResult {
  final double accuracy;
  final double completeness;
  final double fluency;
  final double prosody;
  final double pronScore;
  final List<WordResult> words;

  AssessmentResult({
    required this.accuracy,
    required this.completeness,
    required this.fluency,
    required this.prosody,
    required this.pronScore,
    required this.words,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> result) {
    // final result = json["result"];
    // if (result == null) {
    //   throw Exception("Missing result field");
    // }

    final nbestList = result["NBest"];
    if (nbestList == null || nbestList.isEmpty) {
      throw Exception("Missing NBest list");
    }

    final nbest = nbestList[0];

    // final pa = nbest["PronunciationAssessment"] ?? {};
    final pa = nbest;

    return AssessmentResult(
      accuracy: (pa["AccuracyScore"] ?? 0).toDouble(),
      completeness: (pa["CompletenessScore"] ?? 0).toDouble(),
      fluency: (pa["FluencyScore"] ?? 0).toDouble(),
      prosody: (pa["ProsodyScore"] ?? 0).toDouble(),
      pronScore: (pa["PronScore"] ?? 0).toDouble(),
      words: ((nbest["Words"] ?? []) as List)
          .map((w) => WordResult.fromJson(w))
          .toList(),
    );
  }

}

class WordResult {
  final String word;
  final double accuracy;

  WordResult({required this.word, required this.accuracy});

  factory WordResult.fromJson(Map<String, dynamic> json) {
    final pa = json["PronunciationAssessment"] ?? {};

    return WordResult(
      word: json["Word"] ?? "",
      accuracy: (pa["AccuracyScore"] ?? 0).toDouble(),
    );
  }

}
