import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class votesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> showNotificationDialog(BuildContext context, String message, String notificationId, {bool canVote = true}) async {
    // Ottieni i dati della notifica per includere l'URL della foto
    DocumentSnapshot notificationSnapshot = await FirebaseFirestore.instance.collection('notifications').doc(notificationId).get();
    Map<String, dynamic> notificationData = notificationSnapshot.exists ? notificationSnapshot.data() as Map<String, dynamic> : {};
    String? photoUrl = notificationData['photo']; // Ottieni l'URL della foto, se esiste

    // Ottieni i dati di voto
    DocumentSnapshot voteSnapshot = await FirebaseFirestore.instance.collection('votes').doc(notificationId).get();
    Map<String, dynamic> voteData = voteSnapshot.exists
        ? voteSnapshot.data() as Map<String, dynamic>
        : {
      'upvotes': 0,
      'downvotes': 0,
      'voters': <String, bool>{},
    };

    String voterId = FirebaseAuth.instance.currentUser!.uid;
    bool? previousVote = voteData['voters'][voterId] as bool?;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dettagli Notifica"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8, // Limita la larghezza massima del dialogo
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(message),
                  const SizedBox(height: 10),
                  // Visualizza la foto se l'URL è presente
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    Image.network(
                      photoUrl,
                      height: 200, // Puoi regolare l'altezza secondo le tue esigenze
                      width: double.infinity,
                      fit: BoxFit.cover, // Imposta l'immagine per coprire l'intera area disponibile
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Errore nel caricamento della foto'); // Gestione errori di caricamento immagine
                      },
                    ),
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
            ),
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
        'voteId': notificationId,
        'upvotes': 0,
        'downvotes': 0,
        'voters': <String, bool>{},
      };

      bool? previousVote = voteData['voters'][voterId] as bool?;

      if (previousVote == null) {
        // Nuovo voto
        voteData['voters'][voterId] = isUpvote;
        if (isUpvote) {
          voteData['upvotes']++;
        } else {
          voteData['downvotes']++;
        }
      } else if (previousVote == isUpvote) {
        // Voto annullato
        voteData['voters'].remove(voterId);
        if (isUpvote) {
          voteData['upvotes']--;
        } else {
          voteData['downvotes']--;
        }

        print('Voto annullato.');
      } else {
        // Cambio voto
        voteData['voters'][voterId] = isUpvote;
        if (isUpvote) {
          voteData['upvotes']++;
          voteData['downvotes']--;
        } else {
          voteData['downvotes']++;
          voteData['upvotes']--;
        }
      }

      // Salva solo i dati di upvotes e downvotes nella collezione 'votes'
      await voteRef.set(voteData);
    } catch (e) {
      print('Errore durante il voto: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getVotes(String profileId) async {
    try {
      // Fetch notifications for the given profile from 'notificationsOld'
      QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notificationsOld')
          .where('senderId', isEqualTo: profileId)
          .get();

      List<Map<String, dynamic>> votesList = [];

      // Check if there are any notifications
      if (notificationsSnapshot.docs.isEmpty) {
        return votesList;
      }

      // Extract notification IDs
      List<String> notificationIds = notificationsSnapshot.docs.map((doc) => doc.id).toList();

      // Fetch votes for the notifications from the 'votes' collection
      QuerySnapshot voteSnapshot = await FirebaseFirestore.instance
          .collection('votes')
          .where(FieldPath.documentId, whereIn: notificationIds)
          .get();

      // Create a map for quick lookup of votes by notification ID
      Map<String, Map<String, dynamic>> notificationVotesMap = {
        for (var doc in voteSnapshot.docs)
          doc.id: {
            'upvotes': doc['upvotes'] as int,
            'downvotes': doc['downvotes'] as int,
          }
      };

      // Combine notifications with their corresponding votes
      for (var doc in notificationsSnapshot.docs) {
        String notificationId = doc.id;
        Map<String, dynamic> notificationData = doc.data() as Map<String, dynamic>;

        // Check if this notification has votes, if not default to 0
        int upvotes = notificationVotesMap[notificationId]?['upvotes'] ?? 0;
        int downvotes = notificationVotesMap[notificationId]?['downvotes'] ?? 0;

        // Add the notification and its votes to the list
        votesList.add({
          'title': notificationData['title'] ?? 'Untitled Notification',
          'message': notificationData['message'] ?? 'no message',
          'upvotes': upvotes,
          'downvotes': downvotes,
        });
      }

      return votesList;
    } catch (e) {
      print('Error fetching votes: $e');
      return [];
    }
  }
}