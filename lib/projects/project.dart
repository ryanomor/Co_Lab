import 'package:flutter/material.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectCard extends StatelessWidget {
  final DocumentSnapshot project;

  const ProjectCard({
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
                project['name'],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: project['progress'] ?? 0,
              ),
              const SizedBox(height: 8),
              Text(
                '${project['tasks']?.length ?? 0} tasks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _buildMemberAvatars(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars() {
    List<dynamic> members = project['members'] ?? [];
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
              child: Text(member.roles[0].toString().toUpperCase()),
            ),
          );
        },
      ),
    );
  }
}
