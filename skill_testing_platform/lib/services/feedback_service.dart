class FeedbackService {
  String generateFeedback(String category, int score, int total, List<Map<String, dynamic>> userAnswers) {
    final percentage = (score / total) * 100;
    String strengthFeedback;
    String improvementFeedback;
    String detailedFeedback = '';

    if (percentage >= 80) {
      strengthFeedback = 'You are STRONG in $category! EXCELLENT PERFORMANCE!';
    } else if (percentage >= 50) {
      strengthFeedback = 'You have a decent grasp of $category, with room to improve.';
    } else {
      strengthFeedback = 'You NEED TO FOCUS more on $category to enhance your skills.';
    }

    int correctCount = 0;
    int mcqCorrect = 0, codingCorrect = 0, debugCorrect = 0, outputCorrect = 0;
    int mcqTotal = 0, codingTotal = 0, debugTotal = 0, outputTotal = 0;

    for (var answer in userAnswers) {
      if (answer['isCorrect'] == true) correctCount++;
      switch (answer['type']) {
        case 'mcq':
          mcqTotal++;
          if (answer['isCorrect']) mcqCorrect++;
          break;
        case 'coding':
          codingTotal++;
          if (answer['isCorrect']) codingCorrect++;
          break;
        case 'debug':
          debugTotal++;
          if (answer['isCorrect']) debugCorrect++;
          break;
        case 'output':
          outputTotal++;
          if (answer['isCorrect']) outputCorrect++;
          break;
      }
    }

    if (correctCount == total) {
      improvementFeedback = 'PERFECT SCORE! Keep exploring ADVANCED topics in $category.';
    } else {
      improvementFeedback = 'You missed ${total - correctCount} questions. FOCUS on weaker areas.';
    }

    if (mcqTotal > 0) {
      detailedFeedback += '\n- MCQs: $mcqCorrect/$mcqTotal (${(mcqCorrect / mcqTotal * 100).toStringAsFixed(1)}%)';
    }
    if (codingTotal > 0) {
      detailedFeedback += '\n- Coding: $codingCorrect/$codingTotal (${(codingCorrect / codingTotal * 100).toStringAsFixed(1)}%)';
    }
    if (debugTotal > 0) {
      detailedFeedback += '\n- Debugging: $debugCorrect/$debugTotal (${(debugCorrect / debugTotal * 100).toStringAsFixed(1)}%)';
    }
    if (outputTotal > 0) {
      detailedFeedback += '\n- Output Prediction: $outputCorrect/$outputTotal (${(outputCorrect / outputTotal * 100).toStringAsFixed(1)}%)';
    }

    detailedFeedback += '\n\nMISSED QUESTIONS:';
    for (var answer in userAnswers) {
      if (!answer['isCorrect']) {
        detailedFeedback += '\n- Q: ${answer['question']}\n  Your Answer: ${answer['userAnswer'] ?? 'None'}\n  Correct Answer: ${answer['correctAnswer'] ?? 'None'}';
      }
    }

    return '''
Score: $score/$total (${percentage.toStringAsFixed(1)}%)
- Strengths: $strengthFeedback
- Areas to Improve: $improvementFeedback
- Detailed Performance:$detailedFeedback
- Next Steps: Practice more ${category.toLowerCase()} questions, focusing on areas with lower scores.
''';
  }
}