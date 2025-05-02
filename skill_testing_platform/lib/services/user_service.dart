import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserProfile(String uid, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'testsTaken': 0,
      'averageScore': 0.0,
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateUserStats(String uid, int score, int total) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final testsTaken = (data['testsTaken'] ?? 0) + 1;
    final currentAvg = data['averageScore'] ?? 0.0;
    final newAvg = ((currentAvg * (testsTaken - 1)) + (score / total * 100)) / testsTaken;

    await userRef.update({
      'testsTaken': testsTaken,
      'averageScore': newAvg,
    });
  }
}