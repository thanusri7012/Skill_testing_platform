import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String text;
  final String type;
  final List<String>? options;
  final int? correctOptionIndex;
  final List<int>? correctOptionIndices;
  final String? correctCode;
  final bool isBold;
  final bool isUnderline;
  final bool? isMultipleChoice;
  final int? numOptions;
  final bool? isCodingQuizMultipleChoice;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.correctOptionIndex,
    this.correctOptionIndices,
    this.correctCode,
    this.isCodingQuizMultipleChoice,
    this.isBold = false,
    this.isUnderline = false,
    this.isMultipleChoice,
    this.numOptions,
  });

  Question copyWith({
    String? id,
    String? text,
    String? type,
    List<String>? options,
    int? correctOptionIndex,
    List<int>? correctOptionIndices,
    String? correctCode,
    bool? isBold,
    bool? isUnderline,
    bool? isMultipleChoice,
    int? numOptions,
    bool? isCodingQuizMultipleChoice,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      correctOptionIndices: correctOptionIndices ?? this.correctOptionIndices,
      correctCode: correctCode ?? this.correctCode,
      isBold: isBold ?? this.isBold,
      isUnderline: isUnderline ?? this.isUnderline,
      isMultipleChoice: isMultipleChoice ?? this.isMultipleChoice,
      numOptions: numOptions ?? this.numOptions,
      isCodingQuizMultipleChoice: isCodingQuizMultipleChoice ?? this.isCodingQuizMultipleChoice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'correctOptionIndices': correctOptionIndices,
      'correctCode': correctCode,
      'isBold': isBold,
      'isUnderline': isUnderline,
      'isMultipleChoice': isMultipleChoice,
      'numOptions': numOptions,
      'isCodingQuizMultipleChoice': isCodingQuizMultipleChoice,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      text: map['text'] as String,
      type: map['type'] as String,
      options: (map['options'] as List<dynamic>?)?.cast<String>(),
      correctOptionIndex: map['correctOptionIndex'] as int?,
      correctOptionIndices: (map['correctOptionIndices'] as List<dynamic>?)?.cast<int>(),
      correctCode: map['correctCode'] as String?,
      isBold: map['isBold'] as bool? ?? false,
      isUnderline: map['isUnderline'] as bool? ?? false,
      isMultipleChoice: map['isMultipleChoice'] as bool?,
      numOptions: map['numOptions'] as int?,
      isCodingQuizMultipleChoice: map['isCodingQuizMultipleChoice'] as bool?,
    );
  }
}

class Test {
  final String id;
  final String title;
  final String description;
  final String? category;
  final int duration;
  final List<Question> questions;
  final String createdBy;

  Test({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    required this.duration,
    required this.questions,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdBy': createdBy,
    };
  }

  factory Test.fromMap(Map<String, dynamic> map) {
    return Test(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String?,
      duration: map['duration'] as int,
      questions: (map['questions'] as List<dynamic>)
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdBy: map['createdBy'] as String,
    );
  }
}