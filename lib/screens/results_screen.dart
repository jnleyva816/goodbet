import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, Map<int, int>> scores;
  final Map<String, String> playerNames;
  final int holes;
  final Map<String, double> bets;

  const ResultsScreen({super.key, 
    required this.scores,
    required this.playerNames,
    required this.holes,
    required this.bets,
  });

  @override
  Widget build(BuildContext context) {
    String winnerId = _calculateWinner();
    String winnerName = playerNames[winnerId] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Scores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Player')),
                    for (int hole = 1; hole <= holes; hole++) DataColumn(label: Text('Hole $hole')),
                    const DataColumn(label: Text('Total')),
                  ],
                  rows: scores.entries.map((entry) {
                    String playerId = entry.key;
                    Map<int, int> playerScores = entry.value;
                    int totalScore = playerScores.values.fold(0, (a, b) => a + b);
                    return DataRow(cells: [
                      DataCell(Text(playerNames[playerId] ?? playerId)),
                      for (int hole = 1; hole <= holes; hole++)
                        DataCell(Text(playerScores[hole]?.toString() ?? '-')),
                      DataCell(Text(totalScore.toString())),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bets',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Player')),
                  DataColumn(label: Text('Bet Amount')),
                ],
                rows: bets.entries.map((entry) {
                  String playerId = entry.key;
                  double betAmount = entry.value;
                  return DataRow(cells: [
                    DataCell(Text(playerNames[playerId] ?? playerId)),
                    DataCell(Text('\$${betAmount.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Total Bets: \$${bets.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Winner: $winnerName',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _distributeBets(context, winnerId),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Distribute Bets'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Players',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ..._buildPlayerDetails(context),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateWinner() {
    Map<String, int> totalScores = {};

    scores.forEach((playerId, playerScores) {
      totalScores[playerId] = playerScores.values.fold(0, (a, b) => a + b);
    });

    String winnerId = totalScores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    return winnerId;
  }

  void _distributeBets(BuildContext context, String winnerId) {
    double totalBets = bets.values.fold(0.0, (a, b) => a + b);
    String winnerName = playerNames[winnerId] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distribute Bets'),
        content: Text('$winnerName wins the total bets of \$${totalBets.toStringAsFixed(2)}!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerDetails(BuildContext context) {
    return playerNames.entries.map((entry) {
      String playerId = entry.key;
      String playerName = entry.value;
      int totalScore = scores[playerId]?.values.fold(0, (a, b) => a! + b) ?? 0;
      double betAmount = bets[playerId] ?? 0.0;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(playerName[0]),
          ),
          title: Text(playerName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Score: $totalScore'),
              Text('Bet Amount: \$${betAmount.toStringAsFixed(2)}'),
            ],
          ),
        ),
      );
    }).toList();
  }
}
