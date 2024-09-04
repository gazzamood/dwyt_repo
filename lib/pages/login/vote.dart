import 'package:cloud_firestore/cloud_firestore.dart';

class VoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVote({
    required String voterId,   // ID dell'utente che sta votando
    required String targetId,  // ID dell'utente o attività che riceve il voto
    required String voteType,  // "user" o "activity"
    required bool voteBool,    // Il valore del voto
  }) async {
    try {
      await _firestore.collection('votes').add({
        'voter_id': voterId,
        'target_id': targetId,
        'vote_type': voteType,
        'vote_value': voteBool,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding vote: $e');
    }
  }
}
