import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skill_testing_platform/models/test.dart';

class FeedbackService {
  final String openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  final String apiKey = ''; // Replace with your Open AI API key

  Future<String> generateFeedback(Test test, Map<int, List<int>> answers, Map<int, String> textAnswers, int score, int total) async {
    return await compute(_generateFeedbackIsolate, {
      'test': test,
      'answers': answers,
      'textAnswers': textAnswers,
      'score': score,
      'total': total,
      'openAiApiUrl': openAiApiUrl,
      'apiKey': apiKey,
    });
  }
}

Future<String> _generateFeedbackIsolate(Map<String, dynamic> params) async {
  final Test test = params['test'] as Test;
  final Map<int, List<int>> answers = params['answers'] as Map<int, List<int>>;
  final Map<int, String> textAnswers = params['textAnswers'] as Map<int, String>;
  final int score = params['score'] as int;
  final int total = params['total'] as int;
  final String openAiApiUrl = params['openAiApiUrl'] as String;
  final String apiKey = params['apiKey'] as String;

  try {
    // Step 1: Gather question data and evaluate answers
    List<Map<String, dynamic>> questionsData = [];
    List<Map<String, dynamic>> correctQuestions = [];
    List<Map<String, dynamic>> incorrectQuestions = [];

    for (int i = 0; i < test.questions.length; i++) {
      final question = test.questions[i];
      final userAnswerRaw = question.type == 'mcq' || (question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false))
          ? (answers[i] ?? []).isNotEmpty
          ? (answers[i] ?? []).map((index) => question.options![index]).join(', ')
          : 'No answer provided'
          : (textAnswers[i] ?? '').isNotEmpty
          ? textAnswers[i]!
          : 'No answer provided';
      final correctAnswerRaw = question.type == 'mcq' || (question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false))
          ? (question.isMultipleChoice ?? false)
          ? (question.correctOptionIndices ?? []).map((index) => question.options![index]).join(', ')
          : question.options![question.correctOptionIndex!]
          : question.correctCode ?? 'No correct answer provided';

      final userAnswer = userAnswerRaw.replaceAll('\n', ' ').trim();
      final correctAnswer = correctAnswerRaw.isEmpty ? 'No correct answer provided' : correctAnswerRaw.replaceAll('\n', ' ').trim();
      final isCorrect = _isAnswerCorrect(question, answers[i], textAnswers[i]);

      questionsData.add({
        'question_number': i + 1,
        'question_text': question.text,
        'user_answer': userAnswer,
        'correct_answer': correctAnswer,
        'is_correct': isCorrect,
        'type': question.type,
        'is_coding_quiz_multiple_choice': question.isCodingQuizMultipleChoice ?? false,
        'is_multiple_choice': question.isMultipleChoice ?? false,
      });

      if (isCorrect) {
        correctQuestions.add({
          'question_number': i + 1,
          'question_text': question.text,
          'user_answer': userAnswer,
          'correct_answer': correctAnswer,
        });
      } else {
        incorrectQuestions.add({
          'question_number': i + 1,
          'question_text': question.text,
          'user_answer': userAnswer,
          'correct_answer': correctAnswer,
        });
      }

      print('Question ${i + 1} - Text: ${question.text}, User Answer: $userAnswer, Correct Answer: $correctAnswer, Is Correct: $isCorrect');
    }

    // Step 2: Generate concise, professional feedback
    final percentage = (score / total * 100);
    final StringBuffer feedbackBuffer = StringBuffer();

    feedbackBuffer.writeln('**Performance Summary**');
    if (percentage >= 80) {
      feedbackBuffer.writeln('Excellent work! You demonstrated a strong understanding of ${test.category} concepts.');
    } else if (percentage >= 50) {
      feedbackBuffer.writeln('Good effort! You have a solid foundation in ${test.category}, with some areas to strengthen.');
    } else {
      feedbackBuffer.writeln('You’ve taken a great first step in ${test.category}. Let’s focus on building your skills further.');
    }
    feedbackBuffer.writeln();

    feedbackBuffer.writeln('**Areas to Improve**');
    if (incorrectQuestions.isEmpty) {
      feedbackBuffer.writeln('You answered all questions correctly! Keep practicing to maintain your skills.');
    } else {
      feedbackBuffer.writeln('Focus on the following concepts to improve:');
      for (var q in incorrectQuestions) {
        feedbackBuffer.writeln('- ${q['question_text'].split(' ').take(5).join(' ')}... (Q${q['question_number']})');
      }
    }
    feedbackBuffer.writeln();

    feedbackBuffer.writeln('**Tips for Improvement**');
    feedbackBuffer.writeln('- Review ${test.category} fundamentals, especially topics related to incorrect answers.');
    feedbackBuffer.writeln('- Practice similar questions to reinforce your understanding.');
    feedbackBuffer.writeln('- Seek resources like tutorials or documentation for deeper insights.');

    // Step 3: Use Open AI to generate a concise, professional analysis
    final prompt = '''
You are an AI assistant providing concise, professional feedback for a skill test in ${test.category}. In 2-3 sentences, summarize the user's performance, highlight key areas for improvement based on incorrect answers, and suggest one actionable step to enhance their skills. Use simple, encouraging language, avoiding mention of specific scores or tables, and focus on the test category and question results.

**Test Category**: ${test.category}
**Questions and Answers**:
${questionsData.map((q) => 'Q${q['question_number']}: Type: ${q['type']}${q['type'] == 'coding' ? ', IsCodingQuizMultipleChoice: ${q['is_coding_quiz_multiple_choice']}' : ''}${q['type'] == 'mcq' ? ', IsMultipleChoice: ${q['is_multiple_choice']}' : ''}, Text: ${q['question_text']}, User Answer: ${q['user_answer']}, Correct Answer: ${q['correct_answer']}, Is Correct: ${q['is_correct']}').join('\n')}
**Correct Questions**:
${correctQuestions.isEmpty ? 'None' : correctQuestions.map((q) => 'Q${q['question_number']}: Text: ${q['question_text']}, User Answer: ${q['user_answer']}, Correct Answer: ${q['correct_answer']}').join('\n')}
**Incorrect Questions**:
${incorrectQuestions.isEmpty ? 'None' : incorrectQuestions.map((q) => 'Q${q['question_number']}: Text: ${q['question_text']}, User Answer: ${q['user_answer']}, Correct Answer: ${q['correct_answer']}').join('\n')}
''';

    print('Prompt being sent to Open AI API:');
    print(prompt);

    final apiUrl = Uri.parse(openAiApiUrl);
    print('Attempting to connect to Open AI API at: $apiUrl');

    http.Response? response;
    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        print('Making API request attempt ${retryCount + 1}...');
        response = await http.post(
          apiUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-3.5-turbo',
            'messages': [
              {
                'role': 'user',
                'content': prompt,
              },
            ],
            'max_tokens': 100, // Reduced for concise response
            'temperature': 0.5, // Lowered for professional responses
          }),
        ).timeout(Duration(seconds: 60), onTimeout: () {
          throw Exception('Request to Open AI API timed out after 60 seconds.');
        });

        print('API request successful on attempt ${retryCount + 1}.');
        break;
      } catch (e) {
        retryCount++;
        print('Attempt $retryCount failed with error: $e');
        if (retryCount == maxRetries) {
          throw Exception('Failed to connect to Open AI API after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }

    String aiFeedback = '';
    if (response == null) {
      aiFeedback = 'Unable to generate detailed feedback due to server issues. Please review the tips above.';
    } else {
      print('Open AI API Response Status: ${response.statusCode}');
      print('Open AI API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        aiFeedback = data['choices']?[0]?['message']?['content']?.toString() ?? 'No feedback generated by the AI. Please review the tips above.';
        if (aiFeedback.isEmpty) {
          aiFeedback = 'The AI generated an empty response. Please review the tips above.';
        }
      } else {
        aiFeedback = 'Failed to generate feedback. Please review the tips above.';
      }
    }

    // Step 4: Append the AI feedback
    feedbackBuffer.writeln();
    feedbackBuffer.writeln('**Personalized Feedback**');
    feedbackBuffer.writeln(aiFeedback);

    return feedbackBuffer.toString();
  } catch (e) {
    print('Error generating feedback: $e');
    return 'Error generating feedback: $e\nPlease try again later.';
  }
}

bool _isAnswerCorrect(Question question, List<int>? answerIndices, String? textAnswer) {
  print('Evaluating correctness for question: ${question.text}');
  print('Question Type: ${question.type}, IsCodingQuizMultipleChoice: ${question.isCodingQuizMultipleChoice}');
  print('Answer Indices: $answerIndices, Text Answer: $textAnswer');

  if (question.type == 'mcq' || (question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false))) {
    if (question.isMultipleChoice ?? false) {
      final correctIndices = question.correctOptionIndices ?? [];
      print('Multiple Choice - Correct Indices: $correctIndices');
      if (answerIndices == null || answerIndices.isEmpty) {
        print('Result: Incorrect (no answer provided)');
        return false;
      }
      final isCorrect = answerIndices.length == correctIndices.length &&
          answerIndices.every((i) => correctIndices.contains(i));
      print('Result: $isCorrect');
      return isCorrect;
    } else {
      final correctIndex = question.correctOptionIndex;
      print('Single Choice - Correct Index: $correctIndex');
      if (answerIndices == null || answerIndices.isEmpty) {
        print('Result: Incorrect (no answer provided)');
        return false;
      }
      final isCorrect = answerIndices[0] == correctIndex;
      print('Result: $isCorrect');
      return isCorrect;
    }
  } else {
    final correctCode = question.correctCode?.trim() ?? '';
    final userAnswer = (textAnswer ?? '').trim();
    final isCorrect = userAnswer.toLowerCase() == correctCode;
    print('Coding Question - Correct Code: "$correctCode", User Answer: "$userAnswer", Normalized User Answer: "${userAnswer.toLowerCase()}", Is Correct: $isCorrect');
    return isCorrect;
  }
}