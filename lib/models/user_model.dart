class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? driveFolderId;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.driveFolderId,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      driveFolderId: json['drive_folder_id'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'drive_folder_id': driveFolderId,
      'is_active': isActive,
    };
  }
}
