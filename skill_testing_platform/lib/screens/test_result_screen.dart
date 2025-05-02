import 'package:flutter/material.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TestResultScreen extends StatelessWidget {
  final Test test;
  final Map<int, List<int>> answers;
  final Map<int, TextEditingController> textControllers;
  final int score;
  final int total;
  final String summarizedFeedback;

  const TestResultScreen({
    super.key,
    required this.test,
    required this.answers,
    required this.textControllers,
    required this.score,
    required this.total,
    required this.summarizedFeedback,
  });

  // Parse the summarizedFeedback into structured sections
  Map<String, dynamic> _parseFeedback(String feedback) {
    final lines = feedback.split('\n');
    Map<String, dynamic> parsedFeedback = {
      'score': '',
      'strengths': '',
      'areasToImprove': '',
      'detailedPerformance': [],
      'missedQuestions': [],
      'nextSteps': '',
    };

    bool inDetailedPerformance = false;
    bool inMissedQuestions = false;

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('Score:')) {
        parsedFeedback['score'] = line;
      } else if (line.startsWith('- Strengths:')) {
        parsedFeedback['strengths'] = line.replaceFirst('- Strengths:', '').trim();
      } else if (line.startsWith('- Areas to Improve:')) {
        parsedFeedback['areasToImprove'] = line.replaceFirst('- Areas to Improve:', '').trim();
      } else if (line.startsWith('- Detailed Performance:')) {
        inDetailedPerformance = true;
        inMissedQuestions = false;
      } else if (line.startsWith('- Next Steps:')) {
        parsedFeedback['nextSteps'] = line.replaceFirst('- Next Steps:', '').trim();
        inDetailedPerformance = false;
        inMissedQuestions = false;
      } else if (line.startsWith('MISSED QUESTIONS:')) {
        inDetailedPerformance = false;
        inMissedQuestions = true;
      } else if (inDetailedPerformance && line.isNotEmpty && line.startsWith('-')) {
        parsedFeedback['detailedPerformance'].add(line);
      } else if (inMissedQuestions && line.isNotEmpty && line.startsWith('-')) {
        parsedFeedback['missedQuestions'].add(line);
      }
    }

    return parsedFeedback;
  }

  @override
  Widget build(BuildContext context) {
    final parsedFeedback = _parseFeedback(summarizedFeedback);

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Test Results',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    color: Colors.blue,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Score Section
                              Text(
                                'Score: $score / $total',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Percentage: ${(score / total * 100).toStringAsFixed(2)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Enhanced Feedback Section
                              Text(
                                'Feedback',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Score
                                    Text(
                                      parsedFeedback['score'],
                                      style: GoogleFonts.lato(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E88E5), // Blue
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Strengths
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Strengths: ',
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            parsedFeedback['strengths'],
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              color: const Color(0xFF43A047), // Green
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Areas to Improve
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Areas to Improve: ',
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            parsedFeedback['areasToImprove'],
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              color: const Color(0xFFF57C00), // Orange
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Detailed Performance
                                    Text(
                                      'Detailed Performance:',
                                      style: GoogleFonts.lato(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...parsedFeedback['detailedPerformance'].map<Widget>((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: Color(0xFFAB47BC), // Purple
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.replaceFirst('- ', ''),
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                  color: const Color(0xFFAB47BC), // Purple
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 12),

                                    // Missed Questions
                                    if (parsedFeedback['missedQuestions'].isNotEmpty) ...[
                                      Text(
                                        'Missed Questions:',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...parsedFeedback['missedQuestions'].map<Widget>((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                size: 8,
                                                color: Color(0xFFE91E63), // Pink
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.replaceFirst('- ', ''),
                                                  style: GoogleFonts.lato(
                                                    fontSize: 16,
                                                    color: const Color(0xFFE91E63), // Pink
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      const SizedBox(height: 12),
                                    ],

                                    // Next Steps
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Next Steps: ',
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            parsedFeedback['nextSteps'],
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              color: const Color(0xFF0288D1), // Light Blue
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                      const SizedBox(height: 30),
                      Text(
                        'Detailed Results',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(test.questions.length, (index) {
                        final question = test.questions[index];
                        final userAnswer = answers[index] ?? [];
                        final isCodingQuizMultipleChoice = question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false);
                        bool isCorrect = false;
                        String userResponse = '';
                        String correctAnswer = '';

                        if (question.type == 'mcq' || isCodingQuizMultipleChoice) {
                          if (question.isMultipleChoice ?? false) {
                            final correctIndices = question.correctOptionIndices ?? [];
                            isCorrect = userAnswer.length == correctIndices.length &&
                                userAnswer.every((i) => correctIndices.contains(i));
                            correctAnswer = correctIndices.map((i) => question.options![i]).join(', ');
                            userResponse = userAnswer.isNotEmpty
                                ? userAnswer.map((i) => question.options![i]).join(', ')
                                : 'None';
                          } else {
                            final selectedOption = userAnswer.isNotEmpty ? userAnswer[0] : null;
                            isCorrect = selectedOption == question.correctOptionIndex;
                            correctAnswer = question.options![question.correctOptionIndex!];
                            userResponse = selectedOption != null ? question.options![selectedOption] : 'None';
                          }
                        } else {
                          userResponse = textControllers[index]?.text.trim() ?? 'None';
                          correctAnswer = question.correctCode?.trim() ?? 'None';
                          isCorrect = userResponse == correctAnswer;
                        }

                        return Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.cancel,
                                      color: isCorrect ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Question ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  question.text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: question.isBold ? FontWeight.bold : FontWeight.normal,
                                    decoration: question.isUnderline ? TextDecoration.underline : TextDecoration.none,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your Answer: $userResponse',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Correct Answer: $correctAnswer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: (index * 100).ms);
                      }),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Back to Home',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate().scale(duration: 400.ms),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}