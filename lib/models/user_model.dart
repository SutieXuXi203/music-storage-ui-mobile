class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? driveFolderId;
  final String? driveFolderName;
  final DateTime? createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.driveFolderId,
    this.driveFolderName,
    this.createdAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.tryParse(json['created_at'].toString());
      } catch (_) {}
    }

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      driveFolderId: json['drive_folder_id'],
      driveFolderName: json['drive_folder_name'],
      createdAt: parsedDate,
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
      'drive_folder_name': driveFolderName,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
