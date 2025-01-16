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
  final String email;
  final String username;
  final String? photoUrl;
  final List<String> joinedProjects;
  final List<Skills> skills;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.joinedProjects = const [],
    this.skills = const [],
    this.role = 'member',
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      joinedProjects: List<String>.from(data['joinedProjects'] ?? []),
      skills: List<Skills>.from(data['skills'] ?? []),
      role: data['role'] ?? 'member',
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'joinedProjects': joinedProjects,
      'skills': skills.map((s) => s.toString().split('.').last).toList(),
      'role': role,
    };
  }
}
