import 'package:co_lab/firebase/helpers.dart';
import 'package:co_lab/firestore/models/task.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final FirebaseRepository repository;
  final Function(TaskStatus) onStatusUpdate;

  const TaskCard({
    super.key,
    required this.task,
    required this.repository,
    required this.onStatusUpdate,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            leading: Container(
              width: 4,
              color: _getPriorityColor(),
            ),
            trailing: PopupMenuButton<TaskStatus>(
              initialValue: task.status,
              onSelected: onStatusUpdate,
              itemBuilder: (context) => TaskStatus.values
                  .map((status) => PopupMenuItem(
                        value: status,
                        child: Text(
                            status.toString().split('.').last.toUpperCase()),
                      ))
                  .toList(),
              child: Chip(
                label:
                    Text(task.status.toString().split('.').last.toUpperCase()),
                backgroundColor: task.status == TaskStatus.done
                    ? Colors.green.shade100
                    : task.status == TaskStatus.inProgress
                        ? Colors.amber.shade100
                        : Colors.grey.shade100,
              ),
            ),
          ),
          if (task.assignedTo != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 16),
                  SizedBox(width: 8),
                  FutureBuilder<UserModel?>(
                    future: repository.getUser(uid: task.assignedTo!),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.userName ?? 'Loading...',
                        style: TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ],
              ),
            ),
          if (task.dueDate != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Due: ${task.dueDate!.toDate().toString().split(' ')[0]}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
