import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_testing_platform/models/test.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createTest(Test test) async {
    await _db.collection('tests').doc(test.id).set(test.toMap());
  }

  Stream<List<Test>> getTests(String userId) {
    return _db
        .collection('tests')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Test.fromMap(doc.data())).toList());
  }

  Future<void> saveTestResult(
      {required String testId,
        required String userId,
        required int score,
        required int total}) async {
    await _db.collection('results').add({
      'testId': testId,
      'userId': userId,
      'score': score,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTest(String testId) async {
    await _db.collection('tests').doc(testId).delete();
  }
}