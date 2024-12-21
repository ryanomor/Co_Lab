import 'package:co_lab/tasks/create_task.dart';
import 'package:co_lab/tasks/task.dart';
import 'package:flutter/material.dart';
import 'package:co_lab/firebase/helpers.dart';
import 'package:co_lab/firestore/models/task.dart';

class ProjectTasksView extends StatelessWidget {
  final String projectId;
  final FirebaseRepository repository;

  const ProjectTasksView({
    super.key, 
    required this.projectId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: repository.getProjectTasks(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No tasks yet'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskCreationScreen(
                          projectId: projectId,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                  child: Text('Create First Task'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              repository: repository,
              onStatusUpdate: (TaskStatus newStatus) async {
                try {
                  await repository.updateTaskStatus(task.id, newStatus);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update task status: $e')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}