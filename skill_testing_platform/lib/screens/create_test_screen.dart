import 'package:flutter/material.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:skill_testing_platform/services/firestore_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  _CreateTestScreenState createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  List<Question> _questions = [];
  final FirestoreService _firestoreService = FirestoreService();
  final Map<int, bool> _boldStates = {};
  final Map<int, bool> _underlineStates = {};
  final Map<int, int> _numOptions = {};
  final Map<int, bool> _isMultipleChoice = {};
  final Map<int, List<int>> _correctOptionIndices = {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addQuestion(String type) {
    setState(() {
      final index = _questions.length;
      _questions.add(Question(
        id: const Uuid().v4(),
        type: type,
        text: '',
        options: type == 'mcq' ? ['', '', '', ''] : null,
        correctOptionIndex: type == 'mcq' ? 0 : null,
        correctOptionIndices: type == 'mcq' ? [] : null,
        correctCode: type != 'mcq' ? '' : null,
        isCodingQuizMultipleChoice: type == 'coding' ? false : null,
        isBold: false,
        isUnderline: false,
        isMultipleChoice: type == 'mcq' ? false : null,
        numOptions: type == 'mcq' ? 4 : null,
      ));
      _boldStates[index] = false;
      _underlineStates[index] = false;
      _numOptions[index] = 4;
      _isMultipleChoice[index] = false;
      _correctOptionIndices[index] = [];
    });
  }

  void _createTest() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} must have a question text')),
        );
        return;
      }
      if (question.type == 'mcq') {
        if (question.options == null || question.options!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('MCQ question ${i + 1} must have at least one option')),
          );
          return;
        }
        for (var option in question.options!) {
          if (option.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('MCQ question ${i + 1} has empty options')),
            );
            return;
          }
        }
        // Normalize MCQ options to lowercase for case-insensitive comparison
        final normalizedOptions = question.options!.map((option) => option.toLowerCase()).toList();
        _questions[i] = _questions[i].copyWith(options: normalizedOptions);
        // Debug log to confirm normalization
        print('MCQ Question ${i + 1} options normalized to: $normalizedOptions');

        if (question.isMultipleChoice ?? false) {
          if (_correctOptionIndices[i]!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Multiple choice question ${i + 1} must have at least one correct option selected')),
            );
            return;
          }
        } else {
          if (question.correctOptionIndex == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Single choice question ${i + 1} must have a correct option selected')),
            );
            return;
          }
        }
      } else if (question.type == 'coding' || question.type == 'debug') {
        if (question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false)) {
          // Handle multiple choice coding quiz
          if (question.options == null || question.options!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Coding question ${i + 1} (Multiple Choice) must have at least one option')),
            );
            return;
          }
          for (var option in question.options!) {
            if (option.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Coding question ${i + 1} (Multiple Choice) has empty options')),
              );
              return;
            }
          }
          // Normalize options to lowercase for case-insensitive comparison
          final normalizedOptions = question.options!.map((option) => option.toLowerCase()).toList();
          _questions[i] = _questions[i].copyWith(options: normalizedOptions);
          // Debug log to confirm normalization
          print('Coding Question ${i + 1} (Multiple Choice) options normalized to: $normalizedOptions');

          if (question.correctOptionIndex == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Coding question ${i + 1} (Multiple Choice) must have a correct option selected')),
            );
            return;
          }
        } else {
          // Handle regular coding/debug question
          if (question.correctCode == null || question.correctCode!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Question ${i + 1} (Coding/Debug) must have a correct answer')),
            );
            return;
          }
          // Normalize correctCode to lowercase for case-insensitive comparison
          _questions[i] = _questions[i].copyWith(
            correctCode: question.correctCode!.toLowerCase(),
          );
          // Debug log to confirm normalization
          print('Coding/Debug Question ${i + 1} correctCode normalized to: ${question.correctCode}');
          // Note: Ensure test-taking logic compares user answer case-insensitively
          // e.g., userAnswer.toLowerCase() == question.correctCode
        }
      }
    }

    final newTest = Test(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      category: _categoryController.text,
      duration: int.parse(_durationController.text),
      questions: _questions,
      createdBy: FirebaseAuth.instance.currentUser!.uid,
    );

    try {
      await _firestoreService.createTest(newTest);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create test: $e')),
      );
    }
  }

  Widget _buildQuestionForm(int index) {
    final question = _questions[index];
    final isCodingQuizMultipleChoice = question.type == 'coding' && (question.isCodingQuizMultipleChoice ?? false);
    final questionController = TextEditingController(text: question.text);
    final numOptions = _numOptions[index] ?? 4;
    final isMultipleChoice = _isMultipleChoice[index] ?? false;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      'Question ${index + 1} (${question.type.toUpperCase()})',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _questions.removeAt(index);
                      _boldStates.remove(index);
                      _underlineStates.remove(index);
                      _numOptions.remove(index);
                      _isMultipleChoice.remove(index);
                      _correctOptionIndices.remove(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.format_bold,
                    color: _boldStates[index] == true ? Colors.blueAccent : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _boldStates[index] = !(_boldStates[index] ?? false);
                      _questions[index] = _questions[index].copyWith(isBold: _boldStates[index]);
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.format_underline,
                    color: _underlineStates[index] == true ? Colors.blueAccent : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _underlineStates[index] = !(_underlineStates[index] ?? false);
                      _questions[index] = _questions[index].copyWith(isUnderline: _underlineStates[index]);
                    });
                  },
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Question Text',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              onChanged: (value) {
                _questions[index] = _questions[index].copyWith(text: value);
              },
              controller: questionController,
              style: GoogleFonts.poppins(
                fontWeight: _boldStates[index] == true ? FontWeight.bold : FontWeight.normal,
                decoration: _underlineStates[index] == true ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
            if (question.type == 'mcq') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: numOptions,
                      hint: Text('Number of Options', style: GoogleFonts.poppins()),
                      isExpanded: true,
                      items: [2, 3, 4].map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value Options', style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _numOptions[index] = value!;
                          final currentOptions = question.options ?? [];
                          final newOptions = List<String>.generate(value, (i) {
                            return i < currentOptions.length ? currentOptions[i] : '';
                          });
                          _questions[index] = _questions[index].copyWith(
                            id: question.id,
                            options: newOptions,
                            numOptions: value,
                            correctOptionIndex: null,
                            correctOptionIndices: [],
                          );
                          _correctOptionIndices[index] = [];
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Text('Multiple Choice', style: GoogleFonts.poppins()),
                      Switch(
                        value: isMultipleChoice,
                        onChanged: (value) {
                          setState(() {
                            _isMultipleChoice[index] = value;
                            _questions[index] = _questions[index].copyWith(
                              id: question.id,
                              isMultipleChoice: value,
                              correctOptionIndex: null,
                              correctOptionIndices: [],
                            );
                            _correctOptionIndices[index] = [];
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...List.generate(numOptions, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Option ${i + 1}',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      final updatedOptions = List<String>.from(_questions[index].options!);
                      updatedOptions[i] = value;
                      _questions[index] = _questions[index].copyWith(options: updatedOptions);
                    },
                    controller: TextEditingController(text: question.options![i]),
                  ),
                );
              }),
              if (isMultipleChoice) ...[
                const SizedBox(height: 12),
                Text(
                  'Select Correct Options',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: List.generate(numOptions, (i) {
                    return ChoiceChip(
                      label: Text('Option ${i + 1}', style: GoogleFonts.poppins()),
                      selected: _correctOptionIndices[index]!.contains(i),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _correctOptionIndices[index]!.add(i);
                          } else {
                            _correctOptionIndices[index]!.remove(i);
                          }
                          _questions[index] = _questions[index].copyWith(
                            id: question.id,
                            correctOptionIndices: _correctOptionIndices[index],
                          );
                        });
                      },
                      selectedColor: Colors.blueAccent.withOpacity(0.2),
                      backgroundColor: Colors.grey[200],
                    );
                  }),
                ),
              ] else ...[
                DropdownButton<int>(
                  value: _questions[index].correctOptionIndex,
                  hint: Text('Select Correct Option', style: GoogleFonts.poppins()),
                  isExpanded: true,
                  items: List.generate(numOptions, (i) {
                    return DropdownMenuItem<int>(
                      value: i,
                      child: Text('Option ${i + 1}', style: GoogleFonts.poppins()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = _questions[index].copyWith(
                        id: question.id,
                        correctOptionIndex: value,
                      );
                    });
                  },
                ),
              ],
            ] else if (question.type == 'coding') ...[
              CheckboxListTile(
                title: Text('Multiple Choice Coding Quiz', style: GoogleFonts.poppins()),
                value: question.isCodingQuizMultipleChoice ?? false,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _questions[index] = _questions[index].copyWith(
                        id: question.id,
                        isCodingQuizMultipleChoice: value,
                        options: ['', '', '', ''],
                        correctOptionIndex: 0,
                      );
                    } else {
                      _questions[index] = _questions[index].copyWith(
                        id: question.id,
                        isCodingQuizMultipleChoice: value,
                        options: null,
                        correctOptionIndex: null,
                      );
                    }
                  });
                },
              ),
              if (isCodingQuizMultipleChoice) ...[
                ...List.generate(4, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Option ${i + 1}',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        final updatedOptions = List<String>.from(_questions[index].options!);
                        updatedOptions[i] = value;
                        _questions[index] = _questions[index].copyWith(options: updatedOptions);
                      },
                      controller: TextEditingController(text: question.options![i]),
                    ),
                  );
                }),
                DropdownButton<int>(
                  value: _questions[index].correctOptionIndex,
                  hint: Text('Select Correct Option', style: GoogleFonts.poppins()),
                  isExpanded: true,
                  items: List.generate(4, (i) {
                    return DropdownMenuItem<int>(
                      value: i,
                      child: Text('Option ${i + 1}', style: GoogleFonts.poppins()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = _questions[index].copyWith(
                        id: question.id,
                        correctOptionIndex: value,
                      );
                    });
                  },
                ),
              ] else ...[
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Correct Code/Answer',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _questions[index] = _questions[index].copyWith(correctCode: value);
                  },
                  controller: TextEditingController(text: question.correctCode),
                  style: GoogleFonts.poppins(),
                ),
              ],
            ] else ...[
              TextField(
                decoration: InputDecoration(
                  labelText: 'Correct Code/Answer',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                onChanged: (value) {
                  _questions[index] = _questions[index].copyWith(correctCode: value);
                },
                controller: TextEditingController(text: question.correctCode),
                style: GoogleFonts.poppins(),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
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
                    'Create Test',
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                  ),
                ],
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
                              Text(
                                'Test Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Test Title',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.description, color: Colors.blueAccent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                maxLines: 3,
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _categoryController,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.category, color: Colors.blueAccent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _durationController,
                                decoration: InputDecoration(
                                  labelText: 'Duration (minutes)',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.timer, color: Colors.blueAccent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                      const SizedBox(height: 30),
                      Text(
                        'Questions',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_questions.length, (index) => _buildQuestionForm(index)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: () => _addQuestion('mcq'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.radio_button_checked, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Add MCQ', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: () => _addQuestion('coding'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.code, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Add Coding', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: () => _addQuestion('debug'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bug_report, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Add Debug', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().scale(duration: 400.ms),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: _createTest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Create Test',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().scale(duration: 400.ms),
                      const SizedBox(height: 20),
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