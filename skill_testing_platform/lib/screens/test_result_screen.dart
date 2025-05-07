import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:skill_testing_platform/services/feedback_service.dart';

class TestResultScreen extends StatefulWidget {
  final Test test;
  final Map<int, List<int>> answers;
  final Map<int, TextEditingController> textControllers;
  final int score;
  final int total;

  const TestResultScreen({
    super.key,
    required this.test,
    required this.answers,
    required this.textControllers,
    required this.score,
    required this.total,
  });

  @override
  _TestResultScreenState createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  late Future<String> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the feedback future
    final feedbackService = FeedbackService();
    _feedbackFuture = feedbackService.generateFeedback(
      widget.test,
      widget.answers,
      widget.textControllers.map((key, controller) => MapEntry(key, controller.text)),
      widget.score,
      widget.total,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                'Score: ${widget.score} / ${widget.total}',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Percentage: ${(widget.score / widget.total * 100).toStringAsFixed(2)}%',
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
                                child: FutureBuilder<String>(
                                  future: _feedbackFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Text(
                                        'Error: ${snapshot.error}',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      );
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return Text(
                                        'No feedback available.',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      );
                                    } else {
                                      return MarkdownBody(
                                        data: snapshot.data!,
                                        styleSheet: MarkdownStyleSheet(
                                          h2: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E88E5), // Blue
                                          ),
                                          p: GoogleFonts.lato(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                          listBullet: GoogleFonts.lato(
                                            fontSize: 16,
                                            color: const Color(0xFF43A047), // Green for strengths, etc.
                                          ),
                                          tableHead: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          tableBody: GoogleFonts.lato(
                                            fontSize: 16,
                                            color: const Color(0xFFAB47BC), // Purple for table content
                                          ),
                                          tableBorder: const TableBorder(
                                            top: BorderSide(color: Colors.grey),
                                            bottom: BorderSide(color: Colors.grey),
                                            left: BorderSide(color: Colors.grey),
                                            right: BorderSide(color: Colors.grey),
                                            verticalInside: BorderSide(color: Colors.grey),
                                            horizontalInside: BorderSide(color: Colors.grey),
                                          ),
                                        ),
                                      );
                                    }
                                  },
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
                      ...List.generate(widget.test.questions.length, (index) {
                        final question = widget.test.questions[index];
                        final userAnswer = widget.answers[index] ?? [];
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
                          userResponse = widget.textControllers[index]?.text.trim() ?? 'None';
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