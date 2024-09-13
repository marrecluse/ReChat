import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_chat_app/data/message-model.dart';
import 'package:my_chat_app/data/profiles-model.dart';
import 'package:my_chat_app/presentation/login-screen/login_screen.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';

/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.
class ChatPage extends StatefulWidget {
  final String chatroomId;
  final String chatRoomName;

  const ChatPage({
    Key? key,
    required this.chatRoomName,
    required this.chatroomId,
  }) : super(key: key);

  static Route<void> route(
      {required String chatroomId, required String chatRoomName}) {
    return MaterialPageRoute(
      builder: (context) => ChatPage(
        chatroomId: chatroomId,
        chatRoomName: chatRoomName,
      ),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};
  List<Message> _messages = [];

 @override
void initState() {
  super.initState();
  final myUserId = supabase.auth.currentUser!.id;
  _messagesStream = supabase
      .from('messages')
      .select()
      .eq('chatroom_id', widget.chatroomId)
      .order('created_at')
      .asStream()
      .map((maps) => maps
          .map((map) => Message.fromMap(map: map, myUserId: myUserId))
          .toList());

  // Subscribe to real-time changes for the messages table
  supabase
      .channel('public:messages')
      .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chatroom_id',
              value: widget.chatroomId),
          callback: (payload) {
            final newMessage =
                Message.fromMap(map: payload.newRecord, myUserId: myUserId);
            setState(() {
              _messages.insert(0, newMessage); // Add new message at the top
            });
          })
      .subscribe();
}


  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
        await supabase.from('users').select().eq('id', profileId).single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  enableDrag: true,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return InviteToChatBottomSheet(
                      chatroom_id: widget.chatroomId,
                    );
                  },
                );
              },
              icon: FaIcon(FontAwesomeIcons.circlePlus))
        ],
        title: Text(
          widget.chatRoomName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            final allMessages = [
              ..._messages,
              ...?snapshot.data
            ]; // Combine real-time and initial data

            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('Start your conversation now :)'),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: allMessages.length,
                          itemBuilder: (context, index) {
                            // final message = messages[index];
                            final message = allMessages[index];

                            /// I know it's not good to include code that is not related
                            /// to rendering the widget inside build method, but for
                            /// creating an app quick and dirty, it's fine 😂
                            _loadProfileCache(message.sender_id);

                            return _ChatBubble(
                              message: message,
                              profile: _profileCache[message.sender_id],
                            );
                          },
                        ),
                ),
                _MessageBar(
                  chatroom_id: widget.chatroomId,
                ),
              ],
            );
          } else {
            return preloader;
          }
        },
      ),
    );
  }
}

class InviteToChatBottomSheet extends StatefulWidget {
  final String? chatroom_id;
  InviteToChatBottomSheet({
    required this.chatroom_id,
  });
  @override
  _InviteToChatBottomSheetState createState() =>
      _InviteToChatBottomSheetState();
}

class _InviteToChatBottomSheetState extends State<InviteToChatBottomSheet> {
  final _emailController = TextEditingController();
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
              'Invite a friend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Enter email'),
            ),
            SizedBox(height: 16),
            // TextField(
            //   controller: _descriptionController,
            //   decoration: InputDecoration(labelText: 'Description'),
            // ),
            SizedBox(height: 24),
            chatroomProvider.isCreatingChatroom
                ? CircularProgressIndicator() // Show progress indicator
                : ElevatedButton(
                    onPressed: () {
                      // Show the progress indicator while creating chatroom
                      if (_emailController.text.isNotEmpty) {
                        setState(() {
                          chatroomProvider.joinChatroom(widget.chatroom_id!,
                              _emailController.text, context);
                        });
                      }
                    },
                    child: Text('Invite'),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  String chatroom_id;
  _MessageBar({
    Key? key,
    required this.chatroom_id,
  }) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _submitMessage(widget.chatroom_id),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage(String chatroom_id) async {
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'sender_id': myUserId,
        'content': text,
        'chatroom_id': widget.chatroom_id
      });

  // Step 2: Update the chatroom with the new last message and timestamp
    await supabase.from('chatrooms').update({
      'last_message': text, // Assuming 'last_message' field exists
      'last_activity': DateTime.now().toUtc().toIso8601String() // Update timestamp
    }).eq('id', chatroom_id);


     final chatroomProvider =Provider.of<ChatroomProvider>(context);
    chatroomProvider.fetchChatroomDetails(supabase.auth.currentUser!.id);

    } on PostgrestException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final chatRoomProvider = Provider.of<ChatroomProvider>(context);

    List<Widget> chatContents = [
      if (!message.isMine)
        CircleAvatar(
          backgroundImage: profile?.profilePicUrl != null
              ? NetworkImage(profile!.profilePicUrl!) as ImageProvider
              : AssetImage(defaultAvatar) as ImageProvider,
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Column(
          crossAxisAlignment: message.isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!message.isMine && profile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  profile!.username ?? 'Unknown User', // Handle null username
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: message.isMine
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.isMine ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}
