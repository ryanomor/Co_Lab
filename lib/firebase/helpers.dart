import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:co_lab/firestore/models/task.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Methods
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // Project Methods
  Future<String> createProject(ProjectModel project) async {
    DocumentReference docRef = await _firestore.collection('projects').add(project.toFirestore());
    return docRef.id;
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
    DocumentReference docRef = await _firestore.collection('tasks').add(task.toFirestore());
    return docRef.id;
  }

  Stream<List<TaskModel>> getProjectTasks(String projectId) {
    return _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  // Project Invitation Methods
  Future<void> inviteToProject(String projectId, String email) async {
    await _firestore.collection('projects').doc(projectId).update({
      'invitedUsers': FieldValue.arrayUnion([email])
    });
  }

  Future<void> acceptProjectInvitation(String projectId, String userId) async {
    WriteBatch batch = _firestore.batch();
    
    // Add user to project members
    DocumentReference projectRef = _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'members': FieldValue.arrayUnion([{
        'userId': userId,
        'role': 'member',
        'joinedAt': Timestamp.now()
      }])
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