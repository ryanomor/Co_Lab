import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/firestore/models/task.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Methods
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).update(userData);
  }

  Future<void> deleteUser({String? uid, String? email, String? phoneNumber}) async {
    if (uid == null && email == null && phoneNumber == null) {
      throw ArgumentError('Either userId, email, or phoneNumber must be provided');
    }

    if (uid != null) {
      await _firestore.collection('users').doc(uid).delete();
    } else {
      String field = email != null ? 'email' : 'phoneNumber';
      String value = email ?? phoneNumber!;
      
      QuerySnapshot query = await _firestore
          .collection('users')
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return;
      await query.docs.first.reference.delete();
    }
  }

  Future<UserModel?> getUser({String? uid, String? email, String? phoneNumber}) async {
    if (uid == null && email == null && phoneNumber == null) {
      throw ArgumentError('Either userId, email, or phoneNumber must be provided');
    }
    
    DocumentSnapshot? doc;
    
    if (uid != null) {
      doc = await _firestore.collection('users').doc(uid).get();
    } else {
      QuerySnapshot query;
      if (email != null) {
        query = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
      } else {
        query = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) return null;
      doc = query.docs.first;
    }
    
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // Project Methods
  Future<String> createProject(ProjectModel project) async {
    DocumentReference docRef =
        await _firestore.collection('projects').add(project.toFirestore());
    return docRef.id;
  }

  Future<ProjectModel?> getProject(String projectId) async {
    DocumentSnapshot doc =
        await _firestore.collection('projects').doc(projectId).get();
    return doc.exists ? ProjectModel.fromFirestore(doc) : null;
  }

  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // Task Methods
  Future<String> createTask(TaskModel task) async {
    DocumentReference docRef =
        await _firestore.collection('tasks').add(task.toFirestore());
    return docRef.id;
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    await _firestore
        .collection('tasks')
        .doc(taskId)
        .update({'status': newStatus.toString().split('.').last});
  }

  Stream<List<TaskModel>> getProjectTasks(String projectId) {
    return _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Project Invitation Methods
  Future<void> inviteToProject(ProjectInvitation invitation) async {
    await _firestore.collection('invitations').add(invitation.toMap());
    await _firestore.collection('projects').doc(invitation.projectId).update({
      'invitedUsers': FieldValue.arrayUnion([invitation.inviteeId])
    });
  }

  Future<void> acceptProjectInvitation(String projectId, String userId) async {
    WriteBatch batch = _firestore.batch();

    // Add user to project members
    DocumentReference projectRef =
        _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'members': FieldValue.arrayUnion([
        {'userId': userId, 'role': 'member', 'joinedAt': Timestamp.now()}
      ])
    });

    // Update user's joined projects
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'joinedProjects': FieldValue.arrayUnion([projectId])
    });

    await batch.commit();
  }

  // Error Handling Wrapper
  Future<T> handleFirebaseOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Exception _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('You do not have permission to perform this action');
      case 'not-found':
        return Exception('The requested resource was not found');
      default:
        return Exception('Firebase error: ${e.message}');
    }
  }
}
