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

  Future<void> calculateUserFidelity(String uid, String role) async {
    try {
      // Recupera il documento dei voti dell'utente
      DocumentSnapshot voteSnapshot = await _firestore.collection('votes').doc(uid).get();

      if (voteSnapshot.exists) {
        Map<String, dynamic> voteData = voteSnapshot.data() as Map<String, dynamic>;

        int upvotes = voteData['upvotes'] ?? 0;
        int downvotes = voteData['downvotes'] ?? 0;

        // Calcola la fedeltà come differenza tra upvotes e downvotes
        int fidelityChange = upvotes - downvotes;

        // Aggiorna il documento dell'utente
        await _firestore.collection(role).doc(uid).update({
          'fidelity': FieldValue.increment(fidelityChange),
        });
      } else {
        print('Nessun voto trovato per l\'utente: $uid');
      }
    } catch (e) {
      print('Errore durante il calcolo della fedeltà: $e');
    }
  }
}
