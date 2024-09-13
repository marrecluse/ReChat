import 'package:flutter/material.dart';
import 'package:my_chat_app/data/chatroom-model.dart';
import 'package:my_chat_app/data/profiles-model.dart';
import 'package:my_chat_app/data/user-model.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BottomNavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void updateIndex(int newIndex) {
    _currentIndex = newIndex;
    notifyListeners();
  }
}

class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

 // Perform the logout logic
  Future<void> logout() async {
    try {
      // Log out from Supabase
      await Supabase.instance.client.auth.signOut();

      // Clear the user data
      _user = null;
      
      notifyListeners(); // Notify that user data has changed
    } catch (e) {
      print("Logout failed: $e");
    }
  }
  Future<void> fetchUser() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _user = UserModel.fromMap(response);
      notifyListeners();
    } catch (e) {
      // Handle error
      print('Error fetching user: ');
    }
  }

  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userName = prefs.getString('userName');
    final profile_url = prefs.getString('profile_url');

    if (userId != null && userName != null) {
      _user = UserModel(
        id: userId,
        name: userName,
        profile_url: profile_url!,
        email: '',
      );
    }
  }
}

class ChatroomProvider with ChangeNotifier {
  List<ChatroomModel> _chatrooms = [];
  bool _isLoading = false;
  Map<String, String> _cachedSenderNames = {};

  bool isCreatingChatroom = false; // New state

  List<ChatroomModel> get chatrooms => _chatrooms;
  bool get isLoading => _isLoading;
  Future<List<ChatroomModel>> fetchChatroomDetails(String userId) async {
    // Fetch chatrooms where the user is the creator
    final creatorResponse =
        await supabase.from('chatrooms').select().eq('creator_id', userId);
    print('creator response: $creatorResponse');

    final creatorChatrooms = (creatorResponse as List)
        .map((item) => ChatroomModel.fromMap(item))
        .toSet();
    print('creatorCHatrooms: $creatorChatrooms');

    // Fetch chatroom IDs where the user is a member
    final memberResponse = await supabase
        .from('chatroom_members')
        .select('chatroom_id')
        .eq('role', 'member')
        .eq('user_id', userId);

    print('memberResponse: $memberResponse');

    final memberChatroomIds =
        (memberResponse as List).map((item) => item['chatroom_id']).toSet();

    // Fetch chatrooms based on member chatroom IDs
    final memberChatroomsResponse = await supabase
        .from('chatrooms')
        .select()
        .inFilter('id', memberChatroomIds.toList());

    print("memberChatroomsResponse: $memberChatroomsResponse");

    final memberChatrooms = (memberChatroomsResponse as List)
        .map((item) => ChatroomModel.fromMap(item))
        .toSet();

    print('memberChatrooms:$memberChatrooms');

    // Combine creator and member chatrooms
    final allChatrooms = {...creatorChatrooms, ...memberChatrooms};

    print('allChatrooms: $allChatrooms');
    return allChatrooms.toList();
  }




  Future<String> getSenderName(String senderId) async {
    // Check if the name is already cached
    if (_cachedSenderNames.containsKey(senderId)) {
      return _cachedSenderNames[senderId]!;
    }
    try {
      final response =
          await supabase.from('users').select().eq('id', senderId).single();
      _cachedSenderNames[senderId] = response['name'];

      return response['name'];
    } catch (e) {
      debugPrint('error fetching sender name.');
      return 'N/A';
    }
  }

  Future<void> joinChatroom(
      String chatroomId, String email, BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

     // Fetch the user by email
    final userIdResponse =
        await supabase.from('users').select().eq('email', email).limit(1).single();

      final targetUserId = userIdResponse['id'];


    try {

      // Check if the user is already in the chatroom
      final existingMemberResponse = await Supabase.instance.client
          .from('chatroom_members')
          .select()
          .eq('user_id', targetUserId)
          .eq('chatroom_id', chatroomId);

      if (existingMemberResponse.isEmpty) {
        final response = await Supabase.instance.client
            .from('chatroom_members')
            .insert({
          'user_id': userIdResponse['id'],
          'chatroom_id': chatroomId,
          'role': 'member'
        });

        context.showSnackBar(message: 'Added to chatroom');
        Navigator.pop(context);
      } else {
        context.showErrorSnackBar(message: 'Already added');
        Navigator.pop(context);
      }

      // Optionally, show a success message or update the UI
    } catch (e) {
      print('Error joining chatroom: $e');
      context.showErrorSnackBar(message: 'Error adding to chatroom.');
      Navigator.pop(context);

      // Handle the error (e.g., show a snackbar)
    }
  }

  Stream<List<ChatroomModel>> get chatroomStream {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return Supabase.instance.client
        .from(
            'chatrooms:chatroom_members.user_id=eq.$currentUserId') // Real-time filter
        .stream(primaryKey: ['id']) // Replace 'id' with your primary key column
        .map((data) {
      if (data != null) {
        return (data as List<Map<String, dynamic>>)
            .map((item) => ChatroomModel.fromMap(item))
            .toList();
      } else {
        return [];
      }
    });
  }

  // Function to handle the creation of the chatroom
  Future<void> createChatroom(
      String name, String description, BuildContext context) async {
    isCreatingChatroom = true;

    if (name.isNotEmpty) {
      // Create the chatroom and get the chatroom ID
      final chatroomId =
          await _createChatroomInDatabase(name, description, context);
      // Add the current user as a member of the chatroom
      if (chatroomId != null) {
        await _addUserToChatroom(chatroomId, context);
        isCreatingChatroom = false;

        Navigator.of(context).pop(); // Close the bottom sheet
      } else {
        isCreatingChatroom = false;
        context.showErrorSnackBar(message: 'Something went wrong');
        Navigator.of(context).pop(); // Close the bottom sheet
      }
      notifyListeners();
    }
  }

  Future<String?> _createChatroomInDatabase(
      String name, String description, BuildContext context) async {
    try {
      final response = await supabase.from('chatrooms').insert({
        'name': name,
        'description': description,
        'creator_id': supabase
            .auth.currentUser!.id, // Assuming user ID from Supabase auth
      }).select('id');

      context.showSnackBar(message: 'Room created');
      final chatroomId = response[0]['id'] as String?;
      return chatroomId;
    } catch (e) {
      context.showErrorSnackBar(message: 'Error creating chatroom');
      return null;
    }
  }

  Future<void> _addUserToChatroom(
      String chatroomId, BuildContext context) async {
    try {
      final response = await supabase.from('chatroom_members').insert({
        'chatroom_id': chatroomId,
        'user_id': supabase.auth.currentUser!.id,
        'role': 'creator', // or 'member', based on the role
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      context.showErrorSnackBar(message: 'Error adding user to chatroom');
    }
  }

  Future<void> deleteRoom(String chatroomId, BuildContext context) async {
    notifyListeners();
    final response =
        await supabase.from('chatrooms').delete().eq('id', chatroomId);

    notifyListeners();
    fetchChatrooms();

    if (response.error != null) {
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error deleting chatroom: ${response.error!.message}')),
      );
    } else {
      // Notify that the chatroom has been deleted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chatroom deleted successfully')),
      );
    }
  }

  Future<void> fetchChatrooms() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('chatrooms')
          // .select('*, chatroom_members!inner(user_id)')
          .select()
          // .eq('chatroom_members.user_id', currentUserId);
          .eq('creator_id', currentUserId);
      if (response.isNotEmpty) {
        print('rooms response: $response');
        _chatrooms = (response as List)
            .map((item) => ChatroomModel.fromMap(item))
            .toList();
      } else {
        debugPrint('no rooms fetched');
      }
    } catch (error) {
      // Handle errors here, e.g., show a Snackbar
      print('Error fetching chatrooms: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ProfileProvider with ChangeNotifier {
  Profile _profile;

  ProfileProvider(this._profile);

  Profile get profile => _profile;

  void updateProfilePic(String newUrl) {
    _profile.updateProfilePic(newUrl);
    notifyListeners();
  }

  void updateUsername(String newUsername) {
    _profile = Profile(
      id: _profile.id,
      username: newUsername,
      email: _profile.email,
    );
    notifyListeners();
  }
}







// class ChatProvider with ChangeNotifier {


//   List<Mess> _messages = [];
//   bool _isLoading = false;
  
//   List<MessageModel> get messages => _messages;
//   bool get isLoading => _isLoading;

//   Future<void> fetchMessages(String chatroomId) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final response = await Supabase.instance.client
//           .from('messages')
//           .select()
//           .eq('chatroom_id', chatroomId)
//           .order('created_at', ascending: true);

//       _messages = (response as List).map((item) => MessageModel.fromMap(item)).toList();
//     } catch (error) {
//       print('Error fetching messages: $error');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> sendMessage(String chatroomId, String content, String senderId) async {
//     try {
//       await Supabase.instance.client.from('messages').insert({
//         'chatroom_id': chatroomId,
//         'content': content,
//         'sender_id': senderId,
//         'created_at': DateTime.now().toIso8601String(),
//       });
//       fetchMessages(chatroomId);  // Refresh messages after sending
//     } catch (error) {
//       print('Error sending message: $error');
//     }
//   }
// }

