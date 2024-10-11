import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dwyt_test/pages/profile/passFidelity_page/PassFidelityPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../class/Activity.dart';
import '../../services/fidelity_service/fidelityService.dart';
import '../../services/follower_service/followerService.dart';
import '../../services/profile_service/profileService.dart';
import '../../services/votes_service/votesService.dart';
import '../geolocation/map_page.dart';

class ProfilePage extends StatefulWidget {
  final String userRole; // Role: 'users' or 'activities'
  final String profileId; // New parameter for the specific profile to display

  const ProfilePage(this.userRole, this.profileId, {super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  TabController? tabController;
  User? _currentUser;
  String _imageUrl = '';
  String _name = '';
  String _surname = '';
  String _birthdate = '';
  String _addressUser = '';
  //String _phoneNumber = '';
  String _type = '';
  String _description = '';
  String _contacts = '';
  String following = "0"; // Updated following count
  String followers = "0";
  String fidelity = "0";
  double _latitude = 0.0;
  double _longitude = 0.0;


  bool isCurrentUserProfile = false; // New: to check if the profile belongs to the current user
  List<Map<String, dynamic>> votesList = [];
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    // Set the tab controller length dynamically based on the user role
    tabController = TabController(
      length: widget.userRole == 'activities' ? 2 : 2, // Change this length according to your number of tabs
      vsync: this,
    );

    // Check if the profile being viewed is the current user's
    if (_currentUser?.uid == widget.profileId) {
      isCurrentUserProfile = true;
    }

    // Fetch the profile data based on userRole
    if (widget.userRole == 'users') {
      _getUserProfile(widget.profileId);
    } else if (widget.userRole == 'activities') {
      _getActivityProfile(widget.profileId);
    }

    _fetchFollowersCount();
    _checkIfFollowing();
    _fetchFollowingCount(); // Fetch following count on profile load
  }

  Future<void> _fetchFollowersCount() async {
    try {
      // Get the activity document from Firestore
      DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget
          .profileId) // profileId corresponds to the activity's document ID
          .get();

      // Update the followers count in the state
      if (activitySnapshot.exists) {
        setState(() {
          followers = activitySnapshot['followers'].toString();
        });
      } else {
        // If the activity document doesn't exist, set followers to "0"
        setState(() {
          followers = "0";
        });
      }
    } catch (e) {
      print('Error fetching followers count: $e');
    }
  }

  Future<void> _fetchFollowingCount() async {
    try {
      // Ottieni il documento dell'utente per recuperare la lista 'following'
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();

      if (userSnapshot.exists) {
        // Estrai la lista di ID delle attività seguite
        List<dynamic> followingList = userSnapshot['following'] ?? [];

        // Aggiorna lo stato con il numero totale di attività seguite
        setState(() {
          following = followingList.length.toString(); // Mostra il totale degli ID nella lista
        });
      }
    } catch (e) {
      print('Error fetching following count: $e');
    }
  }

  Future<void> _getUserProfile(String profileId) async {
    // Fetch user details using ProfileService
    var profileData = await ProfileService.getUserProfile(profileId);
    setState(() {
      _name = profileData['name'] ?? '';
      _surname = profileData['surname'] ?? '';
      _birthdate = profileData['birthdate'] ?? '';
      _addressUser = profileData['addressUser'] ?? '';
      //_phoneNumber = profileData['phoneNumber'] ?? '';
      fidelity = profileData['fidelity']?.toString() ?? '0';
    });
    await _fetchVotes(profileId, 'users');
  }

  Future<void> _getActivityProfile(String profileId) async {
    var activityData = await ProfileService.getActivityProfile(profileId);
    setState(() {
      _name = activityData['name'] ?? '';
      _type = activityData['type'] ?? '';
      _description = activityData['description'] ?? '';
      _addressUser = activityData['addressActivity'] ?? '';
      _contacts = activityData['contacts'] ?? '';
      fidelity = activityData['fidelity']?.toString() ?? '0';
      _latitude = activityData['latitude'] ?? 0.0;
      _longitude = activityData['longitude'] ?? 0.0;
    });
    await _fetchVotes(profileId, 'activities');
  }

  Future<void> _fetchVotes(String profileId, String collection) async {
    try {
      // Call your method to get the votes
      List<Map<String, dynamic>> fetchedVotes = await votesService.getVotes(profileId);

      // Use setState to update the votesList after fetching data
      setState(() {
        votesList = fetchedVotes;
        print('Votes fetched: ${votesList.length}'); // Debug print statement to verify votes fetching
      });

      // Optionally, you can also handle fidelity calculation here if needed
      int currentFidelity = int.tryParse(fidelity) ?? 0;
      int newFidelity = await FidelityService.calculateFidelity(profileId, currentFidelity, fetchedVotes);

      // Update fidelity in the correct Firestore collection
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(profileId)
          .update({'fidelity': newFidelity});

      // Update fidelity in the state
      setState(() {
        fidelity = newFidelity.toString();
      });
    } catch (e) {
      print('Error fetching votes: $e');
    }
  }

  Future<void> _toggleFollow() async {
    try {
      await FollowerService.followActivity(
          _currentUser!.uid, widget.profileId);

      // Get updated followers count from Firestore after follow/unfollow action
      DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.profileId)
          .get();

      // Update the followers count in the state
      setState(() {
        followers = activitySnapshot['followers']
            .toString(); // Update UI with the new followers count
        _isFollowing = !_isFollowing; // Toggle the follow state
      });

      // Update following count for the current user
      _fetchFollowingCount(); // Fetch and update following count in the UI

      // Show appropriate message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing
              ? 'You are now following this activity'
              : 'You have unfollowed this activity'),
        ),
      );
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling follow status')),
      );
    }
  }

  Future<void> _checkIfFollowing() async {
    try {
      // Get the follower document for the current user
      DocumentSnapshot followerSnapshot = await FirebaseFirestore.instance
          .collection('followers')
          .doc(_currentUser!.uid) // Assuming _currentUser is the logged-in user
          .get();

      if (followerSnapshot.exists) {
        List<dynamic> activityIds = followerSnapshot['activityIds'] ?? [];

        // Check if the current activityId is in the activityIds list
        if (activityIds.contains(widget.profileId)) {
          setState(() {
            _isFollowing = true;
          });
        }
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF4D5B9F),
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
                          _name,
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
                      ],
                      const SizedBox(height: 10.0),
                      Text(
                        " $_contacts",
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
              if (widget.userRole == 'users')
                _buildStatColumn(fidelity, "Fidelity"),
              if (widget.userRole == 'activities')
                _buildStatColumn(followers, "Followers"),
              if (_currentUser != null && _currentUser!.uid != widget.profileId && widget.userRole == 'activities') // Mostra il pulsante solo se l'utente loggato è diverso dal profilo visualizzato e il profilo appartiene a un'attività
                ElevatedButton(
                  onPressed: _toggleFollow, // Chiama il metodo per seguire/smettere di seguire
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D5B9F), // Colore del pulsante
                    foregroundColor: Colors.white, // Colore del testo (bianco)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: Text(_isFollowing ? 'UNFOLLOW' : 'FOLLOW'), // Testo dinamico in base allo stato di follow
                ),
            ],
          ),
          const SizedBox(height: 30.0),
          _buildTabBar(), // Add TabBar widget here
          const SizedBox(height: 10.0),

          // Insert the new Expanded TabBarView here
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                if (widget.userRole == 'activities')
                  _buildDescriptionView()
                else
                  _buildGridView(), // Votes for users

                if (widget.userRole == 'users')
                  const PassFidelityPage() // Usa la nuova pagina per Pass Fidelity
                else
                  _buildGridView(), // Votes for activities
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
      tabs: [
        Tab(text: widget.userRole == 'activities' ? "Description" : "Votes"),
        if (widget.userRole == 'users')
          const Tab(text: "Pass Fidelity"),
        if (widget.userRole == 'activities')
          const Tab(text: "Votes"),
      ],
    );
  }

  GridView _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 4.0,
      ),
      itemCount: votesList.length,
      itemBuilder: (context, index) {
        final voteData = votesList[index];
        int upvotes = voteData['upvotes'] ?? 0;
        int downvotes = voteData['downvotes'] ?? 0;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voteData['title'] ?? 'No title', // Add fallback if no title
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      voteData['message'] ?? 'No message', // Add fallback if no message
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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

  Widget _buildDescriptionView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              // Naviga alla pagina della mappa e mostra la posizione dell'attività
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MapPage(
                    initialActivity: Activity(
                      id: widget.profileId,
                      name: _name,
                      type: _type, // Add the required 'type' parameter
                      addressActivity: _addressUser, // Add the 'addressActivity' parameter using the address you already have
                      latitude: _latitude,
                      longitude: _longitude,
                    )
                  ),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 5.0),
                Text(
                  "Siamo qui",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            _description.isNotEmpty ? _description : "No description available",
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}