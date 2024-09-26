import '../votes_service/votesService.dart';

class FidelityService {

  static Future<int> calculateFidelity(String profileId, int currentFidelity, List<Map<String, dynamic>> fetchedVotes) async {

    // Start from the current fidelity
    //int newFidelity = currentFidelity;

    // Fidelity parte sempre da 0 e ogni volta che recupera la lista dei voti calcola pt
    int newFidelity = 0;

    // Calculate the fidelity based on votes
    for (var vote in fetchedVotes) {
      newFidelity += (vote['upvotes'] as int) - (vote['downvotes'] as int);
    }
    return newFidelity;
  }
}
