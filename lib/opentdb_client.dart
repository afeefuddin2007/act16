import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'quiz_model.dart';

const _quizUrl =
    'https://opentdb.com/api.php?amount=10&category=9&difficulty=easy&type=multiple';

/// Fetches one Class A round. Call only on user action (never in a loop).
/// OpenTDB asks for at least 5 seconds between requests.
Future<List<QuizQuestion>> fetchQuiz({http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final res = await c
        .get(Uri.parse(_quizUrl))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw QuizFetchException('HTTP ${res.statusCode}. Retry later.');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw QuizFetchException('Unexpected response format. Retry.');
    }
    return parseOpenTdb(decoded);
  } on FormatException {
    throw QuizFetchException('Malformed JSON from question service. Retry.');
  } on TimeoutException {
    throw QuizFetchException('Question request timed out. Retry.');
  } on http.ClientException {
    throw QuizFetchException('Network error loading questions. Retry.');
  } finally {
    if (client == null) c.close();
  }
}
