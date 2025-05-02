import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_testing_platform/models/test.dart';

class FirestoreIdSyncer {
  final CollectionReference _testsCollection = FirebaseFirestore.instance.collection('tests');

  Future<void> syncTestIds() async {
    try {
      final snapshot = await _testsCollection.get();
      for (var doc in snapshot.docs) {
        try {
          final test = Test.fromMap(doc.data() as Map<String, dynamic>);
          if (test.id != doc.id) {
            print('ID mismatch for test ${test.id}, Firestore doc ID: ${doc.id}. Fixing...');
            await _testsCollection.doc(doc.id).delete();
            await _testsCollection.doc(test.id).set(test.toMap());
            print('Fixed ID for test ${test.id}');
          }
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
          continue;
        }
      }
      print('Finished syncing test IDs');
    } catch (e) {
      print('Error syncing test IDs: $e');
    }
  }
}