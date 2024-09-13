import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPopupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> showNotificationDialog(BuildContext context, String message, String notificationId, {bool canVote = true}) async {
    DocumentSnapshot voteSnapshot = await _firestore.collection('votes').doc(notificationId).get();
    Map<String, dynamic> voteData = voteSnapshot.exists
        ? voteSnapshot.data() as Map<String, dynamic>
        : {
      'upvotes': 0,
      'downvotes': 0,
      'voters': <String, bool>{},
    };

    String voterId = _auth.currentUser!.uid;
    bool? previousVote = voteData['voters'][voterId] as bool?;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dettagli"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              if (canVote) const SizedBox(height: 20),
              if (canVote)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up),
                          color: (previousVote == true) ? Colors.green : Colors.grey,
                          onPressed: () async {
                            await _submitVote(notificationId, true);
                            Navigator.of(context).pop();
                          },
                        ),
                        Text('${voteData['upvotes']}'),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_down),
                          color: (previousVote == false) ? Colors.red : Colors.grey,
                          onPressed: () async {
                            await _submitVote(notificationId, false);
                            Navigator.of(context).pop();
                          },
                        ),
                        Text('${voteData['downvotes']}'),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Chiudi"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitVote(String notificationId, bool isUpvote) async {
    String voterId = _auth.currentUser!.uid;
    DocumentReference voteRef = _firestore.collection('votes').doc(notificationId);

    try {
      DocumentSnapshot voteSnapshot = await voteRef.get();
      Map<String, dynamic> voteData = voteSnapshot.exists
          ? voteSnapshot.data() as Map<String, dynamic>
          : {
        'upvotes': 0,
        'downvotes': 0,
        'voters': <String, bool>{},
      };

      bool? previousVote = voteData['voters'][voterId] as bool?;

      if (previousVote == null) {
        voteData['voters'][voterId] = isUpvote;
        if (isUpvote) {
          voteData['upvotes']++;
        } else {
          voteData['downvotes']++;
        }
      } else if (previousVote == isUpvote) {
        voteData['voters'].remove(voterId);
        if (isUpvote) {
          voteData['upvotes']--;
        } else {
          voteData['downvotes']--;
        }

        DocumentSnapshot notificationSnapshot = await _firestore.collection('notifications').doc(notificationId).get();

        if (notificationSnapshot.exists) {
          String senderId = notificationSnapshot.get('senderId');
          await _firestore.collection('users').doc(senderId).update({
            'fidelity': FieldValue.increment(isUpvote ? -1 : 1),
          });
        } else {
          print('Notifica non trovata.');
        }

        print('Voto annullato.');
        await voteRef.set(voteData);
        return;
      } else {
        voteData['voters'][voterId] = isUpvote;
        if (isUpvote) {
          voteData['upvotes']++;
          voteData['downvotes']--;
        } else {
          voteData['downvotes']++;
          voteData['upvotes']--;
        }
      }

      DocumentSnapshot notificationSnapshot = await _firestore.collection('notifications').doc(notificationId).get();

      if (notificationSnapshot.exists) {
        String senderId = notificationSnapshot.get('senderId');
        await _firestore.collection('users').doc(senderId).update({
          'fidelity': FieldValue.increment(isUpvote ? 1 : -1),
        });
      } else {
        print('Notifica non trovata.');
      }

      await voteRef.set(voteData);
    } catch (e) {
      print('Errore durante il voto: $e');
    }
  }
}