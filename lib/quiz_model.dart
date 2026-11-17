import 'dart:math';

import 'package:html_unescape/html_unescape.dart';

/// One playable question. [choices] is shuffled once when the model is built.
class QuizQuestion {
  QuizQuestion({
    required this.text,
    required this.choices,
    required this.correct,
  });

  final String text;
  final List<String> choices;
  final String correct;
}

class QuizFetchException implements Exception {
  QuizFetchException(this.message);
  final String message;

  @override
  String toString() => message;
}

final _unescape = HtmlUnescape();

/// Validates an OpenTDB response body and builds exactly 10 playable questions.
/// Throws [QuizFetchException] on any malformed, empty, or incomplete data.
List<QuizQuestion> parseOpenTdb(Map<String, dynamic> json, {Random? rng}) {
  final code = json['response_code'];
  if (code != 0) {
    throw QuizFetchException(
        'Question service returned code $code. Wait a few seconds and retry.');
  }

  final results = json['results'];
  if (results is! List || results.length != 10) {
    throw QuizFetchException('Expected exactly 10 questions. Retry.');
  }

  final random = rng ?? Random();
  final questions = <QuizQuestion>[];

  for (final r in results) {
    if (r is! Map) {
      throw QuizFetchException('Malformed question entry. Retry.');
    }
    if (r['category'] != 'General Knowledge' ||
        r['difficulty'] != 'easy' ||
        r['type'] != 'multiple') {
      throw QuizFetchException('Question metadata did not match Class A. Retry.');
    }

    final text = _unescape.convert('${r['question'] ?? ''}').trim();
    final correct = _unescape.convert('${r['correct_answer'] ?? ''}').trim();
    final wrongRaw = r['incorrect_answers'];
    if (wrongRaw is! List || wrongRaw.length != 3) {
      throw QuizFetchException('Question must have exactly three wrong answers.');
    }
    final wrong =
        wrongRaw.map((e) => _unescape.convert('$e').trim()).toList();
    final choices = [correct, ...wrong];

    if (text.isEmpty ||
        choices.any((c) => c.isEmpty) ||
        choices.toSet().length != 4) {
      throw QuizFetchException('Incomplete or duplicate answer choices. Retry.');
    }

    choices.shuffle(random);
    questions.add(QuizQuestion(text: text, choices: choices, correct: correct));
  }
  return questions;
}
