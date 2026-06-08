import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
// import '../../models/user_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Set<String> _selectedMemberIds = {};
  Map<String, String> _selectedMemberNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsViewModel>().loadAllUsers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text('Create'),
          ),
        ],
      ),
      body: Consumer2<GroupsViewModel, AuthViewModel>(
        builder: (context, groupsViewModel, authViewModel, child) {
          if (groupsViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter group name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a group name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Group description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter group description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Selected members section
                  if (_selectedMemberIds.isNotEmpty) ...[
                    Text(
                      'Selected Members (${_selectedMemberIds.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMemberIds.map((memberId) {
                        final memberName = _selectedMemberNames[memberId] ?? '';
                        return Chip(
                          label: Text(memberName),
                          onDeleted: () => _removeMember(memberId),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Available users section
                  Text(
                    'Select Members',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (groupsViewModel.allUsers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No users found'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupsViewModel.allUsers.length,
                      itemBuilder: (context, index) {
                        final user = groupsViewModel.allUsers[index];
                        final isSelected = _selectedMemberIds.contains(user.uid);
                        final isCurrentUser = user.uid == authViewModel.currentUser?.uid;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            title: Text(user.displayName ?? user.email),
                            subtitle: Text(user.email),
                            value: isSelected,
                            onChanged: isCurrentUser ? null : (bool? value) {
                              if (value == true) {
                                _addMember(user.uid, user.displayName ?? user.email);
                              } else {
                                _removeMember(user.uid);
                              }
                            },
                            secondary: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                (user.displayName ?? user.email)[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addMember(String userId, String userName) {
    setState(() {
      _selectedMemberIds.add(userId);
      _selectedMemberNames[userId] = userName;
    });
  }

  void _removeMember(String userId) {
    setState(() {
      _selectedMemberIds.remove(userId);
      _selectedMemberNames.remove(userId);
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final groupsViewModel = context.read<GroupsViewModel>();

    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a group'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add current user to the group
    final allMemberIds = [..._selectedMemberIds, authViewModel.currentUser!.uid];
    final allMemberNames = Map<String, String>.from(_selectedMemberNames);
    allMemberNames[authViewModel.currentUser!.uid] = 
        authViewModel.currentUser!.displayName ?? authViewModel.currentUser!.email ?? '';

    final groupId = await groupsViewModel.createGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: authViewModel.currentUser!.uid,
      memberIds: allMemberIds,
      memberNames: allMemberNames,
    );

    if (groupId != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ${groupsViewModel.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
