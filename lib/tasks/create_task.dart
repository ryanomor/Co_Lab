import 'package:flutter/material.dart';
import 'package:co_lab/firebase/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/task.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCreationScreen extends StatefulWidget {
  final String projectId;
  final FirebaseRepository repository;

  const TaskCreationScreen({
    super.key,
    required this.projectId,
    required this.repository,
  });

  @override
  _TaskCreationScreenState createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _assignedUserId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Task title is required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final task = TaskModel(
        id: '', // Will be set by Firestore
        projectId: widget.projectId,
        title: _titleController.text,
        description: _descriptionController.text,
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        assignedTo: _assignedUserId,
        status: TaskStatus.todo,
        priority: _selectedPriority,
        dueDate: _selectedDueDate != null
            ? Timestamp.fromDate(_selectedDueDate!)
            : null,
        createdAt: Timestamp.now(),
      );

      await widget.repository.createTask(task);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Task')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                enabled: !_isLoading,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                enabled: !_isLoading,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _selectedPriority,
              items: TaskPriority.values
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(
                            priority.toString().split('.').last.toUpperCase()),
                      ))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
              decoration: InputDecoration(labelText: 'Priority'),
            ),
            SizedBox(height: 16),
            FutureBuilder<ProjectModel?>(
              future: widget.repository.getProject(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();

                final project = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _assignedUserId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...project.members.map((member) => DropdownMenuItem(
                          value: member.userId,
                          child: FutureBuilder<UserModel?>(
                            future: widget.repository.getUser(uid: member.userId),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData)
                                return Text('Loading...');
                              return Text(userSnapshot.data?.username ??
                                  'Unknown User');
                            },
                          ),
                        )),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _assignedUserId = value;
                          });
                        },
                  decoration: InputDecoration(labelText: 'Assign To'),
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedDueDate == null
                      ? 'No due date selected'
                      : 'Due Date: ${_selectedDueDate.toString().split(' ')[0]}'),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _isLoading ? null : _selectDueDate,
                )
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createTask,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text('Create Task'),
            )
          ],
        ),
      ),
    );
  }
}
