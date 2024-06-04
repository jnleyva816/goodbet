import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RoundDetailsScreen extends StatelessWidget {
  final String roundId;

  const RoundDetailsScreen({super.key, required this.roundId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Round Details'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rounds').doc(roundId).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Round not found"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String dateString = data['date'];
          String formattedDateTime = _formatDateTime(dateString);
          double totalBets = data['totalBets']?.toDouble() ?? 0.0;
          Map<String, dynamic> scores = data['scores'] ?? {};

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Date: $formattedDateTime',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Bets: \$${totalBets.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scores:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView(
                    children: scores.entries.map<Widget>((entry) {
                      String userId = entry.key;
                      Map<int, int> playerScores = entry.value.cast<int, int>();
                      int totalScore = _calculateTotalScore(playerScores);
                      return FutureBuilder(
                        future: _getPlayerName(userId),
                        builder: (context, AsyncSnapshot<String> playerNameSnapshot) {
                          if (playerNameSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (playerNameSnapshot.hasError) {
                            return const Text("Error retrieving player name");
                          }
                          if (!playerNameSnapshot.hasData) {
                            return const Text("Player name not found");
                          }
                          String playerName = playerNameSnapshot.data!;
                          return ListTile(
                            title: Text(playerName),
                            subtitle: Text('Total Score: $totalScore'),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> _getPlayerName(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.exists ? userSnapshot['name'] : 'Unknown'; // Replace 'name' with the field name in your user document that stores the user's name
  }

  int _calculateTotalScore(Map<int, int> playerScores) {
    int totalScore = 0;
    for (var score in playerScores.values) {
      totalScore += score;
    }
    return totalScore;
  }

  String _formatDateTime(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = DateFormat('MM-dd-yyyy').format(dateTime); // Format date
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime); // Format time in 12-hour format
    return '$formattedDate - $formattedTime';
  }
}
