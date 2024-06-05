import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'results_screen.dart';
import 'profile_screen.dart';
import '../models/user_model.dart';
import '../models/golf_course_model.dart';

class ScorecardScreen extends StatefulWidget {
  final String roundId;
  final String accessCode;
  final Map<String, dynamic> courseDetails;

  const ScorecardScreen({
    super.key,
    required this.roundId,
    required this.accessCode,
    required this.courseDetails,
  });

  @override
  _ScorecardScreenState createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  Map<String, Map<int, int>> _scores = {};
  List<String> _playerIds = [];
  final Map<String, String> _playerNames = {};
  final Map<String, String> _playerPhotos = {};
  final Map<String, String> _playerHandicaps = {};
  Map<String, double> _bets = {};
  int _holes = 18;
  double _totalBets = 0.0;
  Map<int, Map<String, bool>> _highlightWinners = {};
  Map<int, Map<String, bool>> _highlightLosers = {};
  Map<int, Map<String, bool>> _highlightTies = {};
  bool _isRoundFinished = false;
  late GolfCourse _course;

  late Stream<DocumentSnapshot> _roundStream;

  @override
  void initState() {
    super.initState();
    _course = GolfCourse.fromJson(widget.courseDetails);
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
      Map<String, dynamic> playerNames = roundData['playerNames'] ?? {};

      // Convert dynamic bets to double
      betsMap.forEach((key, value) {
        _bets[key] = (value as num).toDouble();
      });

      // Fetch player names and photos
      await _fetchPlayerData(playerIds, playerNames);

      if (mounted) {
        setState(() {
          _playerIds = playerIds;
          _holes = roundData['holes'] ?? 18;
          _scores = {for (var id in playerIds) id: {}};
          _totalBets = totalBets;
          _isRoundFinished = isRoundFinished;

          // Populate scores
          if (roundData['scores'] != null) {
            (roundData['scores'] as Map<String, dynamic>).forEach((playerId, playerScores) {
              _scores[playerId] = (playerScores as Map<String, dynamic>).map((hole, score) {
                return MapEntry(int.parse(hole), (score as num).toInt());
              });
            });
          }

          // Populate highlights
          _highlightWinners = roundData['highlightWinners'] != null
              ? (roundData['highlightWinners'] as Map<String, dynamic>).map((hole, playerHighlights) {
                  return MapEntry(int.parse(hole), (playerHighlights as Map<String, dynamic>).map((playerId, value) {
                    return MapEntry(playerId, value as bool);
                  }));
                })
              : {};
          _highlightLosers = roundData['highlightLosers'] != null
              ? (roundData['highlightLosers'] as Map<String, dynamic>).map((hole, playerHighlights) {
                  return MapEntry(int.parse(hole), (playerHighlights as Map<String, dynamic>).map((playerId, value) {
                    return MapEntry(playerId, value as bool);
                  }));
                })
              : {};
          _highlightTies = roundData['highlightTies'] != null
              ? (roundData['highlightTies'] as Map<String, dynamic>).map((hole, playerHighlights) {
                  return MapEntry(int.parse(hole), (playerHighlights as Map<String, dynamic>).map((playerId, value) {
                    return MapEntry(playerId, value as bool);
                  }));
                })
              : {};
        });
      }
    }
  }

  Future<void> _fetchPlayerData(List<String> playerIds, Map<String, dynamic> playerNames) async {
    for (String playerId in playerIds) {
      if (!_playerNames.containsKey(playerId)) {
        if (playerNames.containsKey(playerId)) {
          // Player was manually added
          if (mounted) {
            setState(() {
              _playerNames[playerId] = playerNames[playerId];
            });
          }
        } else {
          // Player has an account, fetch from users collection
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(playerId).get();
          if (userDoc.exists) {
            if (mounted) {
              setState(() {
                _playerNames[playerId] = "${userDoc['firstName']} ${userDoc['lastName']}";
                _playerPhotos[playerId] = userDoc['profileImageUrl'] ?? '';
                _playerHandicaps[playerId] = userDoc['handicap']?.toString() ?? '';
              });
            }
          }
        }
      }
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
        'highlightWinners': _highlightWinners.map((key, value) => MapEntry(key.toString(), value)),
        'highlightLosers': _highlightLosers.map((key, value) => MapEntry(key.toString(), value)),
        'highlightTies': _highlightTies.map((key, value) => MapEntry(key.toString(), value)),
      });
      // Navigate to ResultsScreen
      if (mounted) {
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
      }
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
      'playerNames.$newPlayerId': name, // Store player name in the round document
    });

    if (mounted) {
      setState(() {
        _playerNames[newPlayerId] = name;
        _playerIds.add(newPlayerId);
        _bets[newPlayerId] = betAmount;
        _scores[newPlayerId] = {};
        _totalBets += betAmount;
      });
    }
  }

  void _showAddPlayerDialog() {
    String name = '';
    double betAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => name = value,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) => betAmount = double.tryParse(value) ?? 0.0,
              decoration: const InputDecoration(labelText: 'Bet Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addPlayer(name, betAmount);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateScores(String playerId, int hole, int score) {
    if (mounted) {
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

    if (mounted) {
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
        'highlightWinners': _highlightWinners.map((key, value) => MapEntry(key.toString(), value)),
        'highlightLosers': _highlightLosers.map((key, value) => MapEntry(key.toString(), value)),
        'highlightTies': _highlightTies.map((key, value) => MapEntry(key.toString(), value)),
      }).then((_) {
        print('Highlights updated in Firestore');
      }).catchError((e) {
        print('Error updating highlights in Firestore: $e');
      });
    }
  }

  void _finishRound() async {
    await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
      'isRoundFinished': true,
    });
    if (mounted) {
      setState(() {
        _isRoundFinished = true;
      });
    }
  }

  Widget _buildScoreInput(String playerId, int hole) {
    int? currentScore = _scores[playerId]?[hole];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DropdownButton<int>(
        value: currentScore,
        items: List.generate(10, (i) => i).map((score) {
          return DropdownMenuItem(
            value: score,
            child: Center(child: Text(score.toString())),
          );
        }).toList(),
        onChanged: !_isRoundFinished
            ? (value) {
                if (value != null) {
                  _updateScores(playerId, hole, value);
                }
              }
            : null,
        underline: Container(),
        isExpanded: true,
        icon: Container(), // Remove the dropdown arrow
      ),
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

  Widget _buildScoreCard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 15.0, // Add space between columns
          dataRowMinHeight: 100.0, // Set minimum height for rows
          dataRowMaxHeight: 115.0, // Set maximum height for rows
          headingRowHeight: 70.0, // Set a taller height for heading row
          horizontalMargin: 15.0, // Add margin to the left of the table
          columns: [
            const DataColumn(
              label: Padding(
                padding: EdgeInsets.only(left: 8.0, right: 16.0), // Add padding to the left and right
                child: Text('Player'),
              ),
            ),
            for (int hole = 1; hole <= _holes; hole++)
              DataColumn(
                label: InkWell(
                  onTap: () => _showHoleInfoDialog(hole),
                  child: Text('Hole $hole'),
                ),
              ),
          ],
          rows: [
            for (String playerId in _playerIds)
              DataRow(cells: [
                DataCell(
                  InkWell(
                    onTap: () => _showPlayerProfile(playerId),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Add padding around player cell
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: _playerPhotos[playerId] != null && _playerPhotos[playerId]!.isNotEmpty
                                ? CachedNetworkImageProvider(_playerPhotos[playerId]!)
                                : null,
                            child: _playerPhotos[playerId] == null || _playerPhotos[playerId]!.isEmpty
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(_playerNames[playerId] ?? playerId),
                          Text(
                            _playerHandicaps[playerId] != null ? 'Handicap: ${_playerHandicaps[playerId]}' : '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                for (int hole = 1; hole <= _holes; hole++)
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.all(8.0), // Add padding around hole cell
                      child: Container(
                        color: _getCellColor(playerId, hole),
                        child: _buildScoreInput(playerId, hole),
                      ),
                    ),
                  ),
              ]),
          ],
          dividerThickness: 1.0, // Add lines between the rows
        ),
      ),
    );
  }

  void _showHoleInfoDialog(int hole) {
    // Show hole information dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hole $hole Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Par: ${_course.scorecard[0]["$hole"]}'),
            for (var teeBox in _course.teeBoxes)
              Text('${teeBox["name"]}: ${_course.scorecard[1]["$hole"]} yards'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPlayerProfile(String playerId) async {
    if (_playerNames[playerId] == null) {
      // This user was manually added
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Player Profile'),
          content: const Text('This was an added user.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      // Fetch the user data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(playerId).get();
      if (userDoc.exists) {
        final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: user),
          ),
        );
      }
    }
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
            return const Center(child: CircularProgressIndicator());
          }

          var roundData = snapshot.data?.data() as Map<String, dynamic>?;

          if (roundData == null) {
            return const Center(child: Text('No round data available.'));
          }

          var players = roundData['players'] as List<dynamic>? ?? [];
          var bets = roundData['bets'] as Map<String, dynamic>? ?? {};
          var scores = roundData['scores'] as Map<String, dynamic>? ?? {};
          var highlightWinners = roundData['highlightWinners'] as Map<String, dynamic>? ?? {};
          var highlightLosers = roundData['highlightLosers'] as Map<String, dynamic>? ?? {};
          var highlightTies = roundData['highlightTies'] as Map<String, dynamic>? ?? {};
          var playerNames = roundData['playerNames'] as Map<String, dynamic>? ?? {};

          // Update local state with real-time data
          _playerIds = List<String>.from(players);
          _bets = bets.map((key, value) => MapEntry(key, (value as num).toDouble()));
          _totalBets = roundData['totalBets']?.toDouble() ?? 0.0;
          _isRoundFinished = roundData['isRoundFinished'] ?? false;

          // Fetch player names if not already fetched
          _fetchPlayerData(_playerIds, playerNames);

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

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(child: _buildScoreCard()),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1), // Adjust the bottom padding
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Total Bets: \$${_totalBets.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16.0,
                right: 32.0, // Add padding to the right
                child: FloatingActionButton(
                  onPressed: () => _showFloatingMenu(context),
                  child: const Icon(Icons.menu),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFloatingMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Submit Scores'),
            onTap: _isRoundFinished ? null : _submitScores,
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add Player'),
            onTap: _isRoundFinished ? null : _showAddPlayerDialog,
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Finish Round'),
            onTap: _isRoundFinished ? null : _finishRound,
          ),
        ],
      ),
    );
  }
}
