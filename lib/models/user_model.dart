class UserModel {
  String uid;
  String firstName;
  String lastName;
  int handicap;
  double funds;
  String profileImageUrl;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.handicap,
    required this.funds,
    this.profileImageUrl = '',
  });

  get profilePictureUrl => null;

  // Convert a UserModel into a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'handicap': handicap,
      'funds': funds,
      'profileImageUrl': profileImageUrl,
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
    );
  }
}
