import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goodbet/screens/results_screen.dart';

class ScorecardScreen extends StatefulWidget {
  final String roundId;
  final String accessCode;

  ScorecardScreen({required this.roundId, required this.accessCode});

  @override
  _ScorecardScreenState createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  Map<String, Map<int, int>> _scores = {};
  List<String> _playerIds = [];
  Map<String, String> _playerNames = {};
  Map<String, double> _bets = {};
  int _holes = 18;
  double _totalBets = 0.0;
  Map<int, Map<String, bool>> _highlightWinners = {};
  Map<int, Map<String, bool>> _highlightLosers = {};
  Map<int, Map<String, bool>> _highlightTies = {};
  bool _isRoundFinished = false;

  late Stream<DocumentSnapshot> _roundStream;

  @override
  void initState() {
    super.initState();
    _roundStream = FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).snapshots();
    _getRoundData();
  }

  void _getRoundData() async {
    final roundDoc = await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).get();
    final roundData = roundDoc.data();

    if (roundData != null) {
      List<String> playerIds = List<String>.from(roundData['players'] ?? []);
      Map<String, dynamic> betsMap = Map<String, dynamic>.from(roundData['bets'] ?? {});
      double totalBets = roundData['totalBets']?.toDouble() ?? 0.0;
      bool isRoundFinished = roundData['isRoundFinished'] ?? false;

      // Convert dynamic bets to double
      betsMap.forEach((key, value) {
        _bets[key] = (value as num).toDouble();
      });

      // Fetch player names
      for (String playerId in playerIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(playerId).get();
        if (userDoc.exists) {
          _playerNames[playerId] = "${userDoc['firstName']} ${userDoc['lastName']}";
        }
      }

      setState(() {
        _playerIds = playerIds;
        _holes = roundData['holes'] ?? 18;
        _scores = {for (var id in playerIds) id: {}};
        _totalBets = totalBets;
        _isRoundFinished = isRoundFinished;
      });
    }
  }

  void _submitScores() async {
    // Convert scores to a format suitable for Firestore
    Map<String, Map<String, int>> firestoreScores = _scores.map((playerId, scores) {
      return MapEntry(playerId, scores.map((hole, score) {
        return MapEntry(hole.toString(), score);
      }));
    });

    try {
      await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
        'scores': firestoreScores,
        'highlightWinners': _highlightWinners,
        'highlightLosers': _highlightLosers,
        'highlightTies': _highlightTies,
      });
      // Navigate to ResultsScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            scores: _scores,
            playerNames: _playerNames,
            holes: _holes,
            bets: _bets,
          ),
        ),
      );
    } catch (e) {
      print('Error updating scores: $e');
    }
  }

  void _addPlayer(String name, double betAmount) async {
    String newPlayerId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add player to Firestore
    await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
      'players': FieldValue.arrayUnion([newPlayerId]),
      'bets.$newPlayerId': betAmount,
      'scores.$newPlayerId': {},
      'totalBets': FieldValue.increment(betAmount), // Increment total bets
    });

    // Add player to users collection
    await FirebaseFirestore.instance.collection('users').doc(newPlayerId).set({
      'firstName': name.split(' ')[0],
      'lastName': name.split(' ').length > 1 ? name.split(' ')[1] : '',
    });

    // Update local state
    setState(() {
      _playerNames[newPlayerId] = name;
      _playerIds.add(newPlayerId);
      _bets[newPlayerId] = betAmount;
      _scores[newPlayerId] = {};
      _totalBets += betAmount;
    });
  }

  void _showAddPlayerDialog() {
    String name = '';
    double betAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => name = value,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) => betAmount = double.tryParse(value) ?? 0.0,
              decoration: InputDecoration(labelText: 'Bet Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addPlayer(name, betAmount);
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateScores(String playerId, int hole, int score) {
    setState(() {
      _scores[playerId]?[hole] = score;
    });

    // Update Firestore with new scores
    FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
      'scores.$playerId.$hole': score,
    }).then((_) {
      print('Score updated in Firestore');
      _updateHighlights(hole);
    }).catchError((e) {
      print('Error updating Firestore: $e');
    });
  }

  void _updateHighlights(int hole) {
    int? minScore;
    int? maxScore;
    for (String playerId in _playerIds) {
      int score = _scores[playerId]?[hole] ?? 0;
      if (minScore == null || score < minScore) {
        minScore = score;
      }
      if (maxScore == null || score > maxScore) {
        maxScore = score;
      }
    }

    setState(() {
      _highlightWinners[hole] = {};
      _highlightLosers[hole] = {};
      _highlightTies[hole] = {};

      for (String playerId in _playerIds) {
        int score = _scores[playerId]?[hole] ?? 0;
        if (score == minScore && score == maxScore) {
          _highlightTies[hole]?[playerId] = true;
        } else if (score == minScore) {
          _highlightWinners[hole]?[playerId] = true;
        } else if (score == maxScore) {
          _highlightLosers[hole]?[playerId] = true;
        }
      }
    });

    // Update Firestore with new highlights
    FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
      'highlightWinners': _highlightWinners,
      'highlightLosers': _highlightLosers,
      'highlightTies': _highlightTies,
    }).then((_) {
      print('Highlights updated in Firestore');
    }).catchError((e) {
      print('Error updating highlights in Firestore: $e');
    });
  }

  Widget _buildScoreInput(String playerId, int hole) {
    int? currentScore = _scores[playerId]?[hole];
    return DropdownButton<int>(
      value: currentScore,
      items: List.generate(10, (i) => i).map((score) {
        return DropdownMenuItem(
          value: score,
          child: Text(score.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _updateScores(playerId, hole, value);
        }
      },
    );
  }

  Color _getCellColor(String playerId, int hole) {
    if (_highlightWinners[hole] != null && _highlightWinners[hole]?[playerId] == true) {
      return Colors.green;
    } else if (_highlightLosers[hole] != null && _highlightLosers[hole]?[playerId] == true) {
      return Colors.red;
    } else if (_highlightTies[hole] != null && _highlightTies[hole]?[playerId] == true) {
      return Colors.yellow;
    }
    return Colors.transparent;
  }

  void _finishRound() async {
    await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
      'isRoundFinished': true,
    });
    setState(() {
      _isRoundFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scorecard - Code: ${widget.accessCode}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roundStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var roundData = snapshot.data?.data() as Map<String, dynamic>?;

          if (roundData == null) {
            return Center(child: Text('No round data available.'));
          }

          var players = roundData['players'] as List<dynamic>? ?? [];
          var bets = roundData['bets'] as Map<String, dynamic>? ?? {};
          var scores = roundData['scores'] as Map<String, dynamic>? ?? {};
          var highlightWinners = roundData['highlightWinners'] as Map<String, dynamic>? ?? {};
          var highlightLosers = roundData['highlightLosers'] as Map<String, dynamic>? ?? {};
          var highlightTies = roundData['highlightTies'] as Map<String, dynamic>? ?? {};

          // Update local state with real-time data
          _playerIds = List<String>.from(players);
          _bets = bets.map((key, value) => MapEntry(key, (value as num).toDouble()));
          _totalBets = roundData['totalBets']?.toDouble() ?? 0.0;
          _isRoundFinished = roundData['isRoundFinished'] ?? false;

          // Fetch player names if not already fetched
          for (String playerId in _playerIds) {
            if (!_playerNames.containsKey(playerId)) {
              FirebaseFirestore.instance.collection('users').doc(playerId).get().then((userDoc) {
                if (userDoc.exists) {
                  setState(() {
                    _playerNames[playerId] = "${userDoc['firstName']} ${userDoc['lastName']}";
                  });
                }
              });
            }
          }

          // Update scores with real-time data
          _scores = scores.map((playerId, playerScores) {
            return MapEntry(playerId, (playerScores as Map<String, dynamic>).map((hole, score) {
              return MapEntry(int.parse(hole), (score as num).toInt());
            }));
          });

          // Update highlights with real-time data
          _highlightWinners = highlightWinners.map((hole, playerHighlights) {
            return MapEntry(int.parse(hole), (playerHighlights as Map<String, dynamic>).map((playerId, value) {
              return MapEntry(playerId, value as bool);
            }));
          });

          _highlightLosers = highlightLosers.map((hole, playerHighlights) {
            return MapEntry(int.parse(hole), (playerHighlights as Map<String, dynamic>).map((playerId, value) {
              return MapEntry(playerId, value as bool);
            }));
          });

          _highlightTies = highlightTies.map((hole, playerHighlights) {
            return MapEntry(int.parse(hole), (playerHighlights as Map<String, dynamic>).map((playerId, value) {
              return MapEntry(playerId, value as bool);
            }));
          });

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Text(
                  'Total Bets: \$${_totalBets.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 120,
                      child: Center(child: Text('Player')),
                    ),
                    for (int hole = 1; hole <= _holes; hole++)
                      Container(
                        width: 60,
                        child: Center(child: Text('Hole $hole')),
                      ),
                  ],
                ),
                for (String playerId in _playerIds)
                  Row(
                    children: [
                      Container(
                        width: 120,
                        child: Center(child: Text(_playerNames[playerId] ?? playerId)),
                      ),
                      for (int hole = 1; hole <= _holes; hole++)
                        Container(
                          width: 60,
                          color: _getCellColor(playerId, hole),
                          child: _buildScoreInput(playerId, hole),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _submitScores,
              child: Text('Submit Scores'),
            ),
            ElevatedButton(
              onPressed: _showAddPlayerDialog,
              child: Text('Add Player'),
            ),
            ElevatedButton(
              onPressed: _finishRound,
              child: Text('Finish Round'),
            ),
          ],
        ),
      ),
    );
  }
}
