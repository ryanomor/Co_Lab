import 'package:cloud_firestore/cloud_firestore.dart';

// Project Model
class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final Timestamp createdAt;
  final List<ProjectMember> members;
  final ProjectStatus status;
  final List<String> invitedUsers;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
    this.status = ProjectStatus.active,
    this.invitedUsers = const [],
  });

  // Convert Firestore document to ProjectModel
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      members: (data['members'] as List?)
          ?.map((memberData) => ProjectMember.fromMap(memberData))
          .toList() ?? [],
      status: ProjectStatus.values.firstWhere(
        (status) => status.toString() == 'ProjectStatus.${data['status'] ?? 'active'}',
      ),
      invitedUsers: List<String>.from(data['invitedUsers'] ?? []),
    );
  }

  // Convert ProjectModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'members': members.map((member) => member.toMap()).toList(),
      'status': status.toString().split('.').last,
      'invitedUsers': invitedUsers,
    };
  }
}

// Enums and Supporting Classes
enum ProjectStatus { active, archived }
enum ProjectMemberRole { admin, member, viewer }

// Project Member Subclass
class ProjectMember {
  final String userId;
  final ProjectMemberRole role;
  final Timestamp joinedAt;

  ProjectMember({
    required this.userId,
    this.role = ProjectMemberRole.member,
    required this.joinedAt,
  });

  factory ProjectMember.fromMap(Map<String, dynamic> data) {
    return ProjectMember(
      userId: data['userId'] ?? '',
      role: ProjectMemberRole.values.firstWhere(
        (role) => role.toString() == 'ProjectMemberRole.${data['role'] ?? 'member'}',
      ),
      joinedAt: data['joinedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.toString().split('.').last,
      'joinedAt': joinedAt,
    };
  }
}