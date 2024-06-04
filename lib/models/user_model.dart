class UserModel {
  String uid;
  String firstName;
  String lastName;
  int handicap;
  double funds;
  String profileImageUrl;
  String email;
  List<Map<String, dynamic>> gameHistory;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.handicap,
    required this.funds,
    required this.email,
    this.profileImageUrl = '',
    this.gameHistory = const [], // Initialize with an empty list
  });

  // Convert a UserModel into a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'handicap': handicap,
      'funds': funds,
      'profileImageUrl': profileImageUrl,
      'email': email,
      'gameHistory': gameHistory,
    };
  }

  // Convert a Map into a UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      handicap: map['handicap']?.toInt() ?? 0,
      funds: map['funds']?.toDouble() ?? 0.0,
      profileImageUrl: map['profileImageUrl'] ?? '',
      email: map['email'] ?? '',
      gameHistory: List<Map<String, dynamic>>.from(map['gameHistory'] ?? []),
    );
  }
}
