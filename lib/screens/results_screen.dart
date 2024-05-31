import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, Map<int, int>> scores;
  final Map<String, String> playerNames;
  final int holes;
  final Map<String, double> bets;

  ResultsScreen({
    required this.scores,
    required this.playerNames,
    required this.holes,
    required this.bets,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, int> roundsWon = {};
    Map<String, int> roundsLost = {};
    double totalBets = bets.values.fold(0.0, (sum, bet) => sum + bet);

    print('Scores: $scores');
    print('Player Names: $playerNames');
    print('Holes: $holes');
    print('Bets: $bets');

    // Calculate rounds won and lost for each player
    for (int hole = 1; hole <= holes; hole++) {
      List<int> scoresForHole = scores.values.map((scoresMap) => scoresMap[hole] ?? 0).toList();

      if (scoresForHole.isEmpty) continue;

      int minScore = scoresForHole.reduce((a, b) => a < b ? a : b);
      int maxScore = scoresForHole.reduce((a, b) => a > b ? a : b);

      scores.forEach((playerId, scoresMap) {
        if (scoresMap[hole] == minScore) {
          roundsWon[playerId] = (roundsWon[playerId] ?? 0) + 1;
        }
        if (scoresMap[hole] == maxScore) {
          roundsLost[playerId] = (roundsLost[playerId] ?? 0) + 1;
        }
      });
    }

    // Calculate total bets and distribute to the winner(s)
    void distributeBets() {
      // Implement logic to calculate total bets and distribute to the winner(s)
      // For example, distribute equally if there are multiple winners
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Game Results'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: scores.keys.map((playerId) {
                  return ListTile(
                    title: Text(playerNames[playerId] ?? playerId),
                    subtitle: Text(
                      'Rounds Won: ${roundsWon[playerId] ?? 0}, Rounds Lost: ${roundsLost[playerId] ?? 0}, Bet: \$${bets[playerId]?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                  );
                }).toList(),
              ),
            ),
            Text(
              'Total Bets: \$${totalBets.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: distributeBets,
              child: Text('Distribute Bets'),
            ),
          ],
        ),
      ),
    );
  }
}
