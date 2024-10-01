import 'package:flutter/material.dart';

class PassFidelityPage extends StatelessWidget {
  const PassFidelityPage({super.key});

  // Funzione per ottenere le ricompense di fidelità
  List<Map<String, dynamic>> _getPassFidelityRewards() {
    List<Map<String, dynamic>> rewards = [];
    for (int i = 0; i <= 100; i += 10) {
      rewards.add({
        'points': '$i points',
        'reward': 'Reward for $i points',
        'icon': Icons.stars,
      });
    }
    return rewards;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> rewards = _getPassFidelityRewards();

    return WillPopScope(
      onWillPop: () async {
        // Blocca il ritorno indietro
        return Future.value(false);
      },
      child: Scaffold(
        body: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4D5B9F).withOpacity(0.2),
                      const Color(0xFF4D5B9F).withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: Icon(
                      rewards[index]['icon'],
                      color: const Color(0xFF4D5B9F),
                    ),
                  ),
                  title: Text(
                    rewards[index]['points'],
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    rewards[index]['reward'],
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}