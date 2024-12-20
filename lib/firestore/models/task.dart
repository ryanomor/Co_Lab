import 'package:cloud_firestore/cloud_firestore.dart';

// Task Model
class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String createdBy;
  final String? assignedTo;
  final TaskStatus status;
  final TaskPriority priority;
  final Timestamp? dueDate;
  final Timestamp createdAt;
  final List<TaskComment>? comments;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.createdBy,
    this.assignedTo,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    required this.createdAt,
    this.comments,
  });

  // Convert Firestore document to TaskModel
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      assignedTo: data['assignedTo'],
      status: TaskStatus.values.firstWhere(
        (status) => status.toString() == 'TaskStatus.${data['status'] ?? 'todo'}',
      ),
      priority: TaskPriority.values.firstWhere(
        (priority) => priority.toString() == 'TaskPriority.${data['priority'] ?? 'medium'}',
      ),
      dueDate: data['dueDate'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      comments: data['comments'] != null
          ? (data['comments'] as List)
              .map((commentData) => TaskComment.fromMap(commentData))
              .toList()
          : null,
    );
  }

  // Convert TaskModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'comments': comments?.map((comment) => comment.toMap()).toList(),
    };
  }
}

// Enums and Supporting Classes
enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high }

class TaskComment {
  final String userId;
  final String text;
  final Timestamp timestamp;

  TaskComment({
    required this.userId,
    required this.text,
    required this.timestamp,
  });

  factory TaskComment.fromMap(Map<String, dynamic> data) {
    return TaskComment(
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}