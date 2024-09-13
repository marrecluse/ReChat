import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_chat_app/data/chatroom-model.dart';
import 'package:my_chat_app/presentation/chat-screen/chat_screen.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:my_chat_app/utils/extension.dart';
import 'package:provider/provider.dart';

class ChatRooms extends StatefulWidget {
  const ChatRooms({super.key});

  @override
  State<ChatRooms> createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<ChatRooms> {
  late Stream<List<ChatroomModel>> _chatroomsStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final userId = supabase.auth.currentUser!.id;
    final chatroomProvider =Provider.of<ChatroomProvider>(context,listen: false);
    chatroomProvider.fetchChatroomDetails(userId);

    // Fetch chatrooms when the widget is initialized
    _chatroomsStream = Stream.fromFuture(chatroomProvider.fetchChatroomDetails(userId));

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final chatroomProvider =
    //       Provider.of<ChatroomProvider>(context, listen: false);

    //   chatroomProvider.fetchChatrooms();
    // });
  }



  // Function to show bottom sheet for creating a chatroom
  void _showCreateChatroomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return CreateChatroomBottomSheet();
      },
    );
  }

  // Function to handle long press and show confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String chatroomId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this chatroom?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final chatroomProvider =
                    Provider.of<ChatroomProvider>(context, listen: false);
                chatroomProvider.deleteRoom(chatroomId, context);
                Navigator.of(context).pop();
                // Call the delete function
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Clear any resources, streams, or subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatroomProvider = Provider.of<ChatroomProvider>(context);
  String lastMessageTime = '';
   
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    debugPrint("user is : $user");
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Profile and Chats title section
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 24.0,
                        backgroundImage: NetworkImage(
                            user!.profile_url), // Replace with actual image
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      // User name
                      Text(
                        "${user!.name}",
                        style: AppConstants.headingTextStyle,
                      ),
                    ],
                  ),
                  // Notification icon
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.circlePlus),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        enableDrag: true,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return CreateChatroomBottomSheet();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            // Chats title
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chats',
                  style: AppConstants.headingTextStyle.copyWith(fontSize: 28.0),
                ),
              ),
            ),
            // Spacer between the title and list
            const SizedBox(height: AppConstants.defaultPadding),
            // List of chatrooms
            chatroomProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : StreamBuilder<List<ChatroomModel>>(
                        stream: _chatroomsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ));
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                                child: Text('No chatrooms available.'));
                          }

                          final chatrooms = snapshot.data!;
                          print('ch::$chatrooms');
                          
                          return Expanded(
                            child: ListView.builder(
                              itemCount: chatrooms
                                  .length, // Replace with actual number of chatrooms
                              itemBuilder: (context, index) {
                                final chatroom = chatrooms[index];
                                 if (chatroom.lastActivity != null) {
      final formattedTime = DateFormat.jm().format(chatroom.lastActivity!); // Format as desired
      lastMessageTime = formattedTime;
    }
                                return ListTile(
                                    key: ValueKey(chatroom.id),

                                  leading: CircleAvatar(
                                    child: Text(chatroom.name[0],),
                                  ),
                                  title: Text(chatroom.name,style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),),
                                  subtitle: Text(chatroom.lastMessage),
                                  trailing: lastMessageTime.isNotEmpty
          ? Container(
            width: 60,
            height: 30,
            decoration: BoxDecoration(
                          color: Colors.green,
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
              child: Center(
                child: Text(
                  lastMessageTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : null,
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ChatPage(
                                                  chatRoomName: chatroom.name,
                                                  chatroomId: chatroom.id,
                                                )));
                                  },
                                  onLongPress: () => _showDeleteConfirmation(
                                      context, chatroom.id),
                                );
                              },
                            ),
                          );
                        }),
          ],
        ),
      ),
    );
  }
}

class CreateChatroomBottomSheet extends StatefulWidget {
  @override
  _CreateChatroomBottomSheetState createState() =>
      _CreateChatroomBottomSheetState();
}

class _CreateChatroomBottomSheetState extends State<CreateChatroomBottomSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Get the height of the keyboard to adjust the bottom sheet height
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final chatroomProvider = Provider.of<ChatroomProvider>(context);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: keyboardHeight + 16, // Add
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Chatroom',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Chatroom Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 24),
            chatroomProvider.isCreatingChatroom
                ? CircularProgressIndicator() // Show progress indicator
                : ElevatedButton(
                    onPressed: () {
                      // Show the progress indicator while creating chatroom
                      if (_nameController.text.isNotEmpty) {
                        setState(() {
                          chatroomProvider.createChatroom(
                            _nameController.text,
                            _descriptionController.text,
                            context,
                          );
                        });
                      }
                    },
                    child: Text('Create'),
                  ),
          ],
        ),
      ),
    );
  }
}
