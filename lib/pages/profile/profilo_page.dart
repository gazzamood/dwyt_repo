import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/profile_service/profileService.dart';

class ProfilePage extends StatefulWidget {
  final String userRole; // Accepting userRole as a parameter

  const ProfilePage(this.userRole, {super.key});

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
  String _type = '';
  String _description = '';
  String _contacts = '';


  String following = "0";
  String followers = "0";
  String fidelity = "0";

  List<Map<String, dynamic>> votesList = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _user = FirebaseAuth.instance.currentUser; // Get the current user

    // Determine which profile to fetch based on userRole
    if (widget.userRole == 'users') {
      _getUserProfile();
    } else if (widget.userRole == 'activities') {
      _getActivityProfile();
    }
  }

  Future<void> _getUserProfile() async {
    if (_user != null) {
      // Fetch user details using ProfileService
      var profileData = await ProfileService.getUserProfile(_user!.uid);
      setState(() {
        _name = profileData['name'] ?? '';
        _surname = profileData['surname'] ?? '';
        _birthdate = profileData['birthdate'] ?? '';
        _addressUser = profileData['addressUser'] ?? '';
        _phoneNumber = profileData['phoneNumber'] ?? '';
        fidelity = profileData['fidelity']?.toString() ?? '0';
      });
      await _fetchVotes();
    }
  }

  Future<void> _getActivityProfile() async {
    if (_user != null) {
      // Recupera i dettagli dell'attività usando ProfileService
      var activityData = await ProfileService.getActivityProfile(_user!.uid);

      setState(() {
        _name = activityData['name'] ?? ''; // Usa il nome dell'attività
        _type = activityData['type'] ?? ''; // Aggiungi il tipo dell'attività
        _description = activityData['description'] ?? ''; // Aggiungi la descrizione
        _addressUser = activityData['addressActivity'] ?? ''; // Indirizzo dell'attività
        _contacts = activityData['contacts'] ?? ''; // Contatti dell'attività
        fidelity = activityData['fidelity']?.toString() ?? '0'; // Imposta fidelity a 0
      });

      // Recupera eventuali voti associati all'attività se necessario
      await _fetchVotes(); // Puoi implementarlo se applicabile
    }
  }

  Future<void> _fetchVotes() async {
    if (_user == null) return;

    // Fetch all documents from the 'votes' collection
    QuerySnapshot voteSnapshot = await FirebaseFirestore.instance
        .collection('votes')
        .get();

    Map<String, Map<String, int>> notificationVotesMap = {
      for (var doc in voteSnapshot.docs)
        doc.id: {
          'upvotes': doc['upvotes'] as int,
          'downvotes': doc['downvotes'] as int,
        }
    };

    // Fetch notifications based on user ID
    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('notificationsOld')
        .where('senderId', isEqualTo: _user!.uid)
        .get();

    List<Map<String, dynamic>> fetchedVotesList = [];

    for (var doc in notificationsSnapshot.docs) {
      String notificationId = doc.id;

      if (notificationVotesMap.containsKey(notificationId)) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

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

    print('Final votesList: $votesList');
  }

  Future<void> _showEditProfileDialog() async {
    // (Dialog code remains the same)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF4D5B9F),

        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
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
                  backgroundImage: AssetImage('assets/images/photo_profile/emoji_occhiolino.jpg'),
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
                      if (widget.userRole == 'users') ...[
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
                      ] else if (widget.userRole == 'activities') ...[
                        Text(
                          "$_name",
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          "Type: $_type",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          "Description: $_description",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          "Contacts: $_contacts",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
              if (widget.userRole == 'users')
                _buildStatColumn(following, "Following"),
              _buildStatColumn(fidelity, "Fidelity"),
              if (widget.userRole == 'activities')
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
                _buildGridView(),
                _buildPassFidelityView(),
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
      indicatorColor: const Color(0xFF4D5B9F),
      labelColor: Colors.black,
      labelStyle: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelColor: Colors.black26,
      tabs: const [
        Tab(text: "Votes"),
        Tab(text: "Pass Fidelity"),
      ],
    );
  }

  GridView _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 3.0,
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

  Widget _buildPassFidelityView() {
    List<Map<String, dynamic>> rewards = _getPassFidelityRewards();

    return ListView.builder(
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
                colors: [const Color(0xFF4D5B9F).withOpacity(0.2), const Color(0xFF4D5B9F).withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
    );
  }
}