import 'dart:convert';

class GolfCourse {
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final String telephone;
  final double latitude;
  final double longitude;
  final int holes;
  final String website;
  final List<dynamic> ratings;
  final List<dynamic> scorecard;
  final List<dynamic> teeBoxes;

  GolfCourse({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.holes,
    required this.website,
    required this.ratings,
    required this.scorecard,
    required this.teeBoxes,
  });

  factory GolfCourse.fromJson(Map<String, dynamic> json) {
    return GolfCourse(
      name: json['courseName'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      telephone: json['phone'] ?? '',
      latitude: double.parse(json['latitude'] ?? '0.0'),
      longitude: double.parse(json['longitude'] ?? '0.0'),
      holes: json['numberOfHoles'] ?? 0,
      website: json['website'] ?? '',
      ratings: _parseList(json['ratings']),
      scorecard: _parseList(json['scorecard']),
      teeBoxes: _parseList(json['teeBoxes']),
    );
  }

  static List<dynamic> _parseList(dynamic value) {
    if (value is String) {
      return jsonDecode(value) as List<dynamic>;
    } else if (value is List) {
      return value;
    } else {
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'courseName': name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'phone': telephone,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'numberOfHoles': holes,
      'website': website,
      'ratings': ratings,
      'scorecard': scorecard,
      'teeBoxes': teeBoxes,
    };
  }
}
