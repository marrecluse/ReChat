import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_chat_app/data/user-model.dart';
import 'package:my_chat_app/presentation/friend-requests-page/friend_requests_page.dart';
import 'package:my_chat_app/presentation/providers/friends-provider.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:my_chat_app/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPage extends StatefulWidget {
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // Function to handle long press and show confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String friendId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this friend?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
// Use `listen: false` here since this is inside an event handler
                Provider.of<FriendsProvider>(context, listen: false)
                    .removeFriend(friendId);
                Navigator.of(context).pop();
                // Call the delete function
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
          actions: [
            StreamBuilder<int>(
              stream: supabase
                  .from('friendRequests')
                  .select()
                  .eq('recipientId', userId)
                  .eq('status', 'pending')
                  .asStream()
                  .map((data) => data.length),
              builder: (context, snapshot) {
                // Loaded state
                final requestCount = snapshot.data ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        friendsProvider.toggleView();
                      },
                      icon: Icon(
                        friendsProvider.showRequests
                            ? Icons.list_outlined
                            : Icons.notifications,
                      ),
                    ),
                    if (requestCount > 0 && !friendsProvider.showRequests)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$requestCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          ],
          title: Text(
              friendsProvider.showRequests ? 'Friend Requests' : 'Friends')),
      body: Column(
        children: [
          Expanded(
            child: friendsProvider.showRequests
                ? FriendRequestsPage()
                : StreamBuilder<List<UserModel>>(
                    stream: friendsProvider.friendsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No friends found.'));
                      }

                      final friends = snapshot.data!;

                      return ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(friend.profile_url),
                            ),
                            title: Text(friend.name),
                            subtitle: Text(friend.email),
                            trailing: IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmation(context, friend.id);
                                }),
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AddFriendWidget(),
          ),
        ],
      ),
    );
  }
}

class AddFriendWidget extends StatefulWidget {
  @override
  _AddFriendWidgetState createState() => _AddFriendWidgetState();
}

class _AddFriendWidgetState extends State<AddFriendWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Row(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              validator: ValidatorUtils.validateEmail,
              decoration: const InputDecoration(
                labelText: 'Enter friend\'s email',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
              )
            : ElevatedButton(
                onPressed: () async {
                  final isValid = _formKey.currentState!.validate();
                  if (!isValid) {
                    return;
                  }
                  setState(() {
                    _isLoading = true;
                  });
                  // Call this method when you want to hide the keyboard
                  FocusScope.of(context).unfocus();

                  final email = _emailController.text.trim();
                  final currentUserEmail = userProvider.user!.email.trim();
                  if (email.isNotEmpty && email != currentUserEmail) {
                    try {
                      final result =
                          await friendsProvider.sendFriendRequest(email);

                      if (result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend request sent!')),
                        );
                        _emailController.clear();
                        setState(() {
                          _isLoading = false;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to send friend request.')),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    } catch (e) {
                      print('error sending request: $e');
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Friend request sending failed to this email.')),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('Add Friend'),
              ),
      ],
    );
  }
}
