import 'package:cloud_firestore/cloud_firestore.dart';

// User Model
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? profilePicture;
  final List<String> joinedProjects;
  final List<String> skills;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.profilePicture,
    this.joinedProjects = const [],
    this.skills = const [],
    this.role = 'member',
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      profilePicture: data['profilePicture'],
      joinedProjects: List<String>.from(data['joinedProjects'] ?? []),
      skills: List<String>.from(data['skills'] ?? []),
      role: data['role'] ?? 'member',
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'profilePicture': profilePicture,
      'joinedProjects': joinedProjects,
      'skills': skills,
      'role': role,
    };
  }
}