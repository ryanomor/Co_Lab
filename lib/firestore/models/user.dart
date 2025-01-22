import 'package:cloud_firestore/cloud_firestore.dart';

enum Skills {
  editor,
  storyboard,
  projectManagement,
  graphicDesign,
  webDesign,
  development,
  marketing,
  writer,
  illustrator
}

// User Model
class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String username;
  final String? photoUrl;
  final List<String> joinedProjects;
  final List<Skills> skills;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    required this.username,
    this.photoUrl,
    this.joinedProjects = const [],
    this.skills = const [],
  }) {
    // Ensure either email or phone number is provided
    if (email == null && phoneNumber == null) {
      throw ArgumentError('Either email or phoneNumber must be provided');
    }
  }

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      joinedProjects: List<String>.from(data['joinedProjects'] ?? []),
      skills: (data['skills'] as List<dynamic>?)
              ?.map((s) => Skills.values.firstWhere(
                    (e) => e.toString().split('.').last == s,
                    orElse: () => Skills.development,
                  ))
              .toList() ??
          [],
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'username': username,
      'photoUrl': photoUrl,
      'joinedProjects': joinedProjects,
      'skills': skills.map((s) => s.toString().split('.').last).toList(),
    };
  }
}
