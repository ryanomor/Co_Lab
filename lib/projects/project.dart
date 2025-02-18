import 'package:flutter/material.dart';
import 'package:co_lab/firestore/models/task.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:co_lab/firebase/firebase_service.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final FirebaseService firestore = FirebaseService();

  ProjectCard({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to project details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<TaskModel>>(
                  stream: firestore.getProjectTasks(project.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading tasks');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading tasks...');
                    }

                    final tasks = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Matches parent Column's alignment
                      mainAxisSize:
                          MainAxisSize.min, // Takes minimum space needed
                      children: [
                        LinearProgressIndicator(
                          value: tasks.isEmpty ? 0 : 
                          tasks.where((task) => task.status.toString() == 'done').length / tasks.length,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tasks.length} tasks',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }),
              const SizedBox(height: 8),
              _buildMemberAvatars(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars() {
    List<dynamic> members = project.members;
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        itemBuilder: (context, index) {
          ProjectMember member = members[index];

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 16,
              child: Text(member.roles.join(", ")),
            ),
          );
        },
      ),
    );
  }
}
