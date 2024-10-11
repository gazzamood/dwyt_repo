// lib/services/map_service/map_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapService {
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

  Future<void> _submitVote(String notificationId, bool upvote) async {
    // Logica per inviare un voto alla notifica
    final docRef = FirebaseFirestore.instance.collection('votes').doc(notificationId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'upvotes': upvote ? 1 : 0,
          'downvotes': upvote ? 0 : 1,
          'voters': {FirebaseAuth.instance.currentUser!.uid: upvote},
        });
      } else {
        int upvotes = snapshot['upvotes'] ?? 0;
        int downvotes = snapshot['downvotes'] ?? 0;

        if (upvote) {
          upvotes++;
        } else {
          downvotes++;
        }

        transaction.update(docRef, {
          'upvotes': upvotes,
          'downvotes': downvotes,
          'voters.${FirebaseAuth.instance.currentUser!.uid}': upvote,
        });
      }
    });
  }
}