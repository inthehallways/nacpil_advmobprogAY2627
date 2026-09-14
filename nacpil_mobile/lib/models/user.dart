class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String age;
  final String contactNo;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final String loginType;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.age = '',
    this.contactNo = '',
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.loginType = 'dummyjson',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? json['fName'] ?? '',
      lastName: json['lastName'] ?? json['lName'] ?? '',
      age: json['age']?.toString() ?? '',
      contactNo: json['contactNo']?.toString() ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '',
      accessToken: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      loginType: json['loginType'] ?? 'dummyjson',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginType': loginType,
    };
  }
}
