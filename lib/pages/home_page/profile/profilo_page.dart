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

    // Step 1: Ottieni tutti i documenti della collezione 'votes'
    QuerySnapshot voteSnapshot = await FirebaseFirestore.instance
        .collection('votes')
        .get();

    // Crea una mappa che associa ogni notificationId ai suoi corrispondenti valori di upvotes e downvotes
    Map<String, Map<String, int>> notificationVotesMap = {
      for (var doc in voteSnapshot.docs)
        doc.id: {
          'upvotes': doc['upvotes'] as int,
          'downvotes': doc['downvotes'] as int,
        }
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

        // Recupera i valori di upvotes e downvotes dalla mappa
        int upvotes = notificationVotesMap[notificationId]?['upvotes'] ?? 0;
        int downvotes = notificationVotesMap[notificationId]?['downvotes'] ?? 0;

        fetchedVotesList.add({
          'title': data['title'] ?? '',
          'upvotes': upvotes,
          'downvotes': downvotes,
        });
      }
    }

    setState(() {
      votesList = fetchedVotesList;
    });

    // Log finale per confermare i dati memorizzati in votesList
    print('Final votesList: $votesList');
  }

  // Funzione per mostrare il dialogo di modifica del profilo
  Future<void> _showEditProfileDialog() async {
    TextEditingController nameController = TextEditingController(text: _name);
    TextEditingController surnameController = TextEditingController(text: _surname);
    TextEditingController birthdateController = TextEditingController(text: _birthdate);
    TextEditingController addressController = TextEditingController(text: _addressUser);
    TextEditingController phoneNumberController = TextEditingController(text: _phoneNumber);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: surnameController,
                  decoration: const InputDecoration(labelText: 'Surname'),
                ),
                TextField(
                  controller: birthdateController,
                  decoration: const InputDecoration(labelText: 'Birthdate'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Aggiorna i dati dell'utente nel Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .update({
                  'name': nameController.text,
                  'surname': surnameController.text,
                  'birthdate': birthdateController.text,
                  'addressUser': addressController.text,
                  'phoneNumber': phoneNumberController.text,
                });

                // Aggiorna lo stato locale
                setState(() {
                  _name = nameController.text;
                  _surname = surnameController.text;
                  _birthdate = birthdateController.text;
                  _addressUser = addressController.text;
                  _phoneNumber = phoneNumberController.text;
                });

                Navigator.of(context).pop(); // Chiudi il dialogo
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog, // Apre il dialogo di modifica del profilo
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/emoji_occhiolino.jpg'),
                  radius: 70.0,
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        "$_name $_surname",
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        " $_birthdate",
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        " $_addressUser",
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        " $_phoneNumber",
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(following, "Following"),
              _buildStatColumn(fidelity, "Fidelity"),
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
        crossAxisCount: 1,  // Una sola colonna per riga
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 3.0, // Cambia il rapporto di aspetto per dare più spazio alla riga
      ),
      itemCount: votesList.length,
      itemBuilder: (context, index) {
        final voteData = votesList[index];
        int upvotes = voteData['upvotes'];
        int downvotes = voteData['downvotes'];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.grey.shade200,
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  voteData['title'],
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_up,
                        color: Colors.green,
                        size: 30.0,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        '$upvotes',
                        style: const TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_down,
                        color: Colors.red,
                        size: 30.0,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        '$downvotes',
                        style: const TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}