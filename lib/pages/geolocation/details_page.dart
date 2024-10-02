import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../class/Activity.dart';
import '../../../class/Notification.dart' as not;

class DetailsPage extends StatelessWidget {
  final Activity? activity;
  final not.Notification? notification;

  const DetailsPage({super.key, this.activity, this.notification});

  Future<String> _getSenderName() async {
    if (notification == null || notification!.senderId.isEmpty) {
      return 'Unknown';
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(notification!.senderId)
          .get();
      return userDoc.data()?['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity?.name ?? 'Notification Details'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activity != null) ...[
                    Text(
                      activity!.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4D5B9F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Type: ${activity!.type}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Opening Hours: ${activity!.openingHours}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Address: ${activity!.addressActivity}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (activity!.contacts != null)
                      Text(
                        'Contacts: ${activity!.contacts}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (activity!.description != null)
                      Text(
                        activity!.description!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 16.0),
                  ],
                  if (notification != null) ...[
                    Text(
                      'Notification Details',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4D5B9F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Title: ${notification!.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Message: ${notification!.message}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Radius: ${notification!.radius} km',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<String>(
                      future: _getSenderName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return const Text('Error fetching sender name');
                        }
                        return Text(
                          'Sent by: ${snapshot.data}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.thumb_up,
                            color: Colors.green,
                            size: 32,
                          ),
                          onPressed: () {
                            // Handle thumbs up action
                          },
                        ),
                        const SizedBox(width: 30),
                        IconButton(
                          icon: const Icon(
                            Icons.thumb_down,
                            color: Colors.red,
                            size: 32,
                          ),
                          onPressed: () {
                            // Handle thumbs down action
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}