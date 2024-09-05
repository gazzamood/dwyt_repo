import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  TabController? tabController;

  User? _user;
  String _imageUrl = '';
  String _name = '';
  String _surname = '';
  String _birthdate = '';
  String _addressUser = '';
  String _phoneNumber = '';

  String following = "0";
  String followers = "0";
  String fidelity = "0";

  List<Map<String, dynamic>> votesList = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _getUserProfile();
    _fetchUserVotes(); // Fetch votes when initializing the state
  }

  Future<void> _getUserProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _user = currentUser;
      });

      // Fetch additional user details from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _name = userSnapshot['name'] ?? '';
        _surname = userSnapshot['surname'] ?? '';
        _birthdate = userSnapshot['birthdate'] ?? '';
        _addressUser = userSnapshot['addressUser'] ?? '';
        _phoneNumber = userSnapshot['phoneNumber'] ?? '';
        fidelity = userSnapshot['fidelity']?.toString() ?? '0'; // Load the fidelity score
      });
    }
  }

  Future<void> _fetchUserVotes() async {
    if (_user == null) return;

    // Step 1: Ottieni tutti i documenti della collezione 'votes' che contengono gli ID delle notifiche valide
    QuerySnapshot voteSnapshot = await FirebaseFirestore.instance
        .collection('votes')
        .get();

    // Crea una mappa che associa ogni notificationId al suo corrispondente valore di vote
    Map<String, bool> notificationVotesMap = {
      for (var doc in voteSnapshot.docs) doc['notificationId'] as String: doc['vote'] as bool
    };

    // Step 2: Ottieni le notifiche dalla collezione 'notifications' filtrate per senderId uguale all'ID dell'utente loggato
    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('senderId', isEqualTo: _user!.uid)
        .get();

    List<Map<String, dynamic>> fetchedVotesList = [];

    for (var doc in notificationsSnapshot.docs) {
      String notificationId = doc.id;

      if (notificationVotesMap.containsKey(notificationId)) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Recupera il valore di vote dalla mappa
        bool vote = notificationVotesMap[notificationId] ?? true;

        // Log per vedere esattamente cosa viene recuperato
        print('Data for notificationId $notificationId: $data');

        fetchedVotesList.add({
          'title': data['title'] ?? '',
          'vote': vote,
        });
      }
    }

    setState(() {
      votesList = fetchedVotesList;
    });

    // Log finale per confermare i dati memorizzati in votesList
    print('Final votesList: $votesList');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/emoji_occhiolino.jpg'),
                  radius: 70.0,
                ),
                const SizedBox(height: 20.0),
                Text(
                  _user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_name $_surname",
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(following, "Following"),
              _buildStatColumn(fidelity, "Fidelity"),  // Added Fidelity between Following and Followers
              _buildStatColumn(followers, "Followers"),
            ],
          ),
          const SizedBox(height: 30.0),
          _buildTabBar(),
          const SizedBox(height: 10.0),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                const Center(child: Text("You don't have any photos")),
                _buildGridView(), // Use _buildGridView to display votes
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        const SizedBox(height: 10.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: tabController,
      indicatorColor: Colors.teal,
      labelColor: Colors.black,
      labelStyle: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelColor: Colors.black26,
      tabs: const [
        Tab(text: "Photos"),
        Tab(text: "Votes"),
      ],
    );
  }

  GridView _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 0.7,
      ),
      itemCount: votesList.length,
      itemBuilder: (context, index) {
        final voteData = votesList[index];
        bool vote = voteData['vote'];

        // Aggiungi un log per verificare il valore del voto
        print('Vote at index $index: $vote');

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.grey.shade200,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vote ? Icons.thumb_up : Icons.thumb_down,
                color: vote ? Colors.green : Colors.red,
                size: 50.0,
              ),
              const SizedBox(height: 10.0),
              Text(
                voteData['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}