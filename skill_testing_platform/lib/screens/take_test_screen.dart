import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TakeTestScreen extends StatefulWidget {
  const TakeTestScreen({super.key});

  @override
  _TakeTestScreenState createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  late Test test;
  int currentQuestionIndex = 0;
  Map<int, List<int>> answers = {};
  Map<int, TextEditingController> textControllers = {};
  int score = 0;
  late Timer _timer;
  int _remainingTime = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        test = ModalRoute.of(context)!.settings.arguments as Test;
        for (int i = 0; i < test.questions.length; i++) {
          textControllers[i] = TextEditingController();
        }
        // Convert duration from minutes to seconds
        _remainingTime = test.duration * 60; // Duration is in minutes, convert to seconds
        startTimer();
      });
    });
  }

  void startTimer() {
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer.cancel();
          _isTimerRunning = false;
          submitTest();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void submitTest() {
    score = 0;
    for (int i = 0; i < test.questions.length; i++) {
      final question = test.questions[i];
      final userAnswer = answers[i] ?? [];
      final isCodingQuizMultipleChoice = question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false);
      if (question.type == 'mcq' || isCodingQuizMultipleChoice) {
        if (question.isMultipleChoice ?? false) {
          final correctIndices = question.correctOptionIndices ?? [];
          if (userAnswer.length == correctIndices.length && userAnswer.every((index) => correctIndices.contains(index))) {
            score++;
          }
        } else {
          if (userAnswer.isNotEmpty && userAnswer[0] == question.correctOptionIndex) {
            score++;
          }
        }
      } else {
        final userResponse = textControllers[i]?.text.trim() ?? '';
        if (userResponse == question.correctCode?.trim()) {
          score++;
        }
      }
    }

    Navigator.pushNamed(
      context,
      '/test_results',
      arguments: {
        'test': test,
        'answers': answers,
        'textControllers': textControllers,
        'score': score,
        'total': test.questions.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!testInitialized()) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = test.questions[currentQuestionIndex];
    final isCodingQuizMultipleChoice = question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false);

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${currentQuestionIndex + 1}/${test.questions.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Time: $_remainingTime s',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: _remainingTime <= 10 ? Colors.red : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: question.isBold ? FontWeight.bold : FontWeight.normal,
                          decoration: question.isUnderline ? TextDecoration.underline : TextDecoration.none,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (question.type == 'mcq' || isCodingQuizMultipleChoice) ...[
                        if (question.isMultipleChoice ?? false)
                          Column(
                            children: List.generate(question.options!.length, (index) {
                              final isSelected = answers[currentQuestionIndex]?.contains(index) ?? false;
                              return CheckboxListTile(
                                title: Text(
                                  question.options![index],
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    answers[currentQuestionIndex] ??= [];
                                    if (value == true) {
                                      answers[currentQuestionIndex]!.add(index);
                                    } else {
                                      answers[currentQuestionIndex]!.remove(index);
                                    }
                                  });
                                },
                              );
                            }).animate().fadeIn(duration: 400.ms),
                          )
                        else
                          Column(
                            children: List.generate(question.options!.length, (index) {
                              final isSelected = answers[currentQuestionIndex]?.contains(index) ?? false;
                              return RadioListTile<int>(
                                title: Text(
                                  question.options![index],
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                value: index,
                                groupValue: answers[currentQuestionIndex]?.isNotEmpty ?? false
                                    ? answers[currentQuestionIndex]![0]
                                    : null,
                                onChanged: (value) {
                                  setState(() {
                                    answers[currentQuestionIndex] = [value!];
                                  });
                                },
                              );
                            }).animate().fadeIn(duration: 400.ms),
                          ),
                      ] else ...[
                        TextField(
                          controller: textControllers[currentQuestionIndex],
                          maxLines: 5,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Enter your code here...',
                            hintStyle: GoogleFonts.poppins(),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                      ],
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (currentQuestionIndex > 0)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestionIndex--;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: Text(
                                'Previous',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (currentQuestionIndex < test.questions.length - 1) {
                                  currentQuestionIndex++;
                                } else {
                                  _timer.cancel();
                                  submitTest();
                                }
                              });
                            },
                            child: Text(
                              currentQuestionIndex == test.questions.length - 1 ? 'Submit' : 'Next',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
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

  bool testInitialized() {
    try {
      return test != null;
    } catch (e) {
      return false;
    }
  }
}