import 'package:flutter/material.dart';
import 'package:co_lab/projects/project.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectListView extends StatelessWidget {
  const ProjectListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('members', arrayContainsAny: [
            {'userId': FirebaseAuth.instance.currentUser?.uid}
          ])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // final projects = snapshot.data?.docs ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            // maxCrossAxisExtent: 300,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // childAspectRatio: 3/2,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final project = snapshot.data!.docs[index];
            return ProjectCard(project: project);
          },
        );
      },
    );
  }
}
