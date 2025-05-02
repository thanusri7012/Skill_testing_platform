import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:skill_testing_platform/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_testing_platform/services/feedback_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_testing_platform/screens/test_result_screen.dart';

class TakeTestScreen extends StatefulWidget {
  const TakeTestScreen({super.key});

  @override
  _TakeTestScreenState createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> with SingleTickerProviderStateMixin {
  late Test test;
  late int remainingSeconds;
  late Timer timer;
  late AnimationController _controller;
  late Animation<double> _animation;
  final FirestoreService _firestoreService = FirestoreService();
  final FeedbackService _feedbackService = FeedbackService();
  int currentQuestionIndex = 0;
  final Map<int, List<int>> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};
  bool _isInitialized = false;
  int _passKeys = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      test = ModalRoute.of(context)!.settings.arguments as Test;
      remainingSeconds = test.duration * 60;
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            timer.cancel();
            _submitTest();
          }
        });
      });
      for (int i = 0; i < test.questions.length; i++) {
        if (test.questions[i].type != 'mcq' && !(test.questions[i].isCodingQuizMultipleChoice ?? false)) {
          _textControllers[i] = TextEditingController();
        }
        _answers[i] = [];
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    timer.cancel();
    _controller.dispose();
    _textControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _submitTest() async {
    int score = 0;
    int total = test.questions.length;
    List<Map<String, dynamic>> userAnswers = [];

    for (int i = 0; i < total; i++) {
      final question = test.questions[i];
      final userAnswer = _answers[i] ?? [];
      final isCodingQuizMultipleChoice = question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false);
      bool isCorrect = false;
      String correctAnswer = '';
      String userResponse = '';

      if (question.type == 'mcq' || isCodingQuizMultipleChoice) {
        if (question.isMultipleChoice ?? false) {
          final correctIndices = question.correctOptionIndices ?? [];
          isCorrect = userAnswer.length == correctIndices.length &&
              userAnswer.every((index) => correctIndices.contains(index));
          correctAnswer = correctIndices.map((index) => question.options![index]).join(', ');
          userResponse = userAnswer.isNotEmpty
              ? userAnswer.map((index) => question.options![index]).join(', ')
              : 'None';
        } else {
          final selectedOption = userAnswer.isNotEmpty ? userAnswer[0] : null;
          isCorrect = selectedOption == question.correctOptionIndex;
          correctAnswer = question.options![question.correctOptionIndex!];
          userResponse = selectedOption != null ? question.options![selectedOption] : 'None';
        }
      } else {
        final controller = _textControllers[i];
        userResponse = controller?.text.trim() ?? 'None';
        correctAnswer = question.correctCode?.trim() ?? 'None';
        isCorrect = userResponse == correctAnswer;
      }

      if (isCorrect) score++;

      userAnswers.add({
        'type': question.type,
        'question': question.text,
        'userAnswer': userResponse,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
      });
    }

    try {
      await _firestoreService.saveTestResult(
        testId: test.id,
        userId: FirebaseAuth.instance.currentUser!.uid,
        score: score,
        total: total,
      );

      final feedback = _feedbackService.generateFeedback(
        test.title,
        score,
        total,
        userAnswers,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultScreen(
            test: test,
            answers: _answers,
            textControllers: _textControllers,
            score: score,
            total: total,
            summarizedFeedback: feedback,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit test: $e')),
      );
    }
  }

  void _passQuestion() {
    if (_passKeys > 0 && currentQuestionIndex < test.questions.length - 1) {
      setState(() {
        _passKeys--;
        currentQuestionIndex++;
        _controller.forward(from: 0);
      });
    } else if (_passKeys == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more pass keys available!')),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final question = test.questions[currentQuestionIndex];
    final isCodingQuizMultipleChoice = question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false);

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
                    test.title,
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Time Remaining: ${_formatTime(remainingSeconds)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Question ${currentQuestionIndex + 1}/${test.questions.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pass Keys: $_passKeys',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                              Row(
                                children: [
                                  Icon(
                                    question.type == 'mcq'
                                        ? Icons.radio_button_checked
                                        : question.type == 'coding'
                                        ? Icons.code
                                        : Icons.bug_report,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Question ${currentQuestionIndex + 1}',
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
                              const SizedBox(height: 20),
                              if (question.type == 'mcq' || isCodingQuizMultipleChoice) ...[
                                if (question.isMultipleChoice ?? false) ...[
                                  ...List.generate(question.options?.length ?? 0, (index) {
                                    return CheckboxListTile(
                                      title: Text(
                                        question.options![index],
                                        style: GoogleFonts.poppins(),
                                      ),
                                      value: _answers[currentQuestionIndex]!.contains(index),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _answers[currentQuestionIndex]!.add(index);
                                          } else {
                                            _answers[currentQuestionIndex]!.remove(index);
                                          }
                                        });
                                      },
                                    );
                                  }),
                                ] else ...[
                                  ...List.generate(question.options?.length ?? 0, (index) {
                                    return RadioListTile<int>(
                                      title: Text(
                                        question.options![index],
                                        style: GoogleFonts.poppins(),
                                      ),
                                      value: index,
                                      groupValue: _answers[currentQuestionIndex]!.isNotEmpty
                                          ? _answers[currentQuestionIndex]![0]
                                          : null,
                                      onChanged: (value) {
                                        setState(() {
                                          _answers[currentQuestionIndex] = [value!];
                                        });
                                      },
                                    );
                                  }),
                                ],
                              ] else ...[
                                TextField(
                                  controller: _textControllers[currentQuestionIndex],
                                  decoration: InputDecoration(
                                    labelText: question.type == 'coding' ? 'Enter your code' : 'Enter debugged code',
                                    labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  maxLines: 5,
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (currentQuestionIndex > 0)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestionIndex--;
                                  _controller.forward(from: 0);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Previous',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: _passQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Pass ($_passKeys)',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (currentQuestionIndex < test.questions.length - 1)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestionIndex++;
                                  _controller.forward(from: 0);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Next',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (currentQuestionIndex == test.questions.length - 1)
                            ElevatedButton(
                              onPressed: _submitTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Submit',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ).animate().scale(duration: 400.ms),
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