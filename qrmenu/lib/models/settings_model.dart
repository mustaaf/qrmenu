class Settings {
  final String? restaurantname;
  final String? logo;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? phoneNumber;

  Settings({
    this.restaurantname,
    this.logo,
    this.facebook,
    this.instagram,
    this.twitter,
    this.phoneNumber,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      restaurantname: json['restaurantName'],
      logo: json['logo'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
      phoneNumber: json['phoneNumber'],
    );
  }

  bool get hasSocialLinks =>
      facebook != null ||
      instagram != null ||
      twitter != null ||
      phoneNumber != null;
}
