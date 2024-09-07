import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:my_chat_app/data/user-model.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsProvider with ChangeNotifier {
  bool _showRequests = false;
  final int requestLength = 0;
  final Map<String, UserModel> _usersCache =
      {}; // Cache to store fetched user details

  bool get showRequests => _showRequests;

  void toggleView() {
    _showRequests = !_showRequests;
    notifyListeners();
  }
  void setDefault(){
    _showRequests = false;
  }

  Stream<List<Map<String, dynamic>>> getFriendRequestsStream() {
    final userId = supabase.auth.currentUser!.id;
    return supabase
        .from('friendRequests')
        .select()
        .eq('recipientId', userId)
        .eq('status', 'pending')
        .asStream()
        .map((data) {
      return data;
    });
  }
  

 Future<bool> rejectFriendRequest(int requestId) async {
    try {
      // Update friend request status
      final updateResponse =
          await Supabase.instance.client.from('friendRequests').update({
        'status': 'rejected',
        'respondedAt':
            DateTime.now().toIso8601String(), // Set current timestamp
      }).eq('id', requestId);

     

      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }





  Future<bool> acceptFriendRequest(int requestId) async {
    try {
      // Update friend request status
      final updateResponse =
          await Supabase.instance.client.from('friendRequests').update({
        'status': 'accepted',
        'respondedAt':
            DateTime.now().toIso8601String(), // Set current timestamp
      }).eq('id', requestId);

      // Get the request details
      final requestResponse = await Supabase.instance.client
          .from('friendRequests')
          .select()
          .eq('id', requestId)
          .single();

      final senderId = requestResponse['senderId'];
      final recipientId = requestResponse['recipientId'];

      // Insert into friends table for both users
      await Supabase.instance.client.from('friends').insert([
        {'user_id': senderId, 'friend_id': recipientId},
        {'user_id': recipientId, 'friend_id': senderId},
      ]);

      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  // This method fetches the sender's name by their ID
  Future<UserModel?> fetchDetails(String senderId) async {
    // Check if the user's name is already cached
    if (_usersCache.containsKey(senderId)) {
      return _usersCache[senderId]!;
    }

    try {
      // Fetch the user details from the database or API
      final response =
          await supabase.from('users').select().eq('id', senderId).single();
      final user = UserModel.fromMap(response);

      // Cache the fetched user details
      _usersCache[senderId] = user;

      return user;
    } catch (error) {
      // Handle errors accordingly
      return null;
    }
  }

  Stream<List<UserModel>> get friendsStream {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return supabase
        .from('friends')
        .stream(primaryKey: ['friend_id'])
        .eq('user_id', userId)
        .asyncMap((data) async {
          if (data.isNotEmpty) {
            final friendIds =
                data.map((friend) => friend['friend_id'] as String).toList();
            final userResponse =
                await supabase.from('users').select().inFilter('id', friendIds);

            if (userResponse.isNotEmpty) {
              return (userResponse as List<Map<String, dynamic>>)
                  .map((item) => UserModel.fromMap(item))
                  .toList();
            } else {
              return [];
            }
          } else {
            return [];
          }
        });
  }

  Future<bool> sendFriendRequest(String email) async {
    final smtpServer = gmail('danijakhar11@gmail.com',
        'ccpu zrwt uofs ahts'); // Use environment variables or a more secure method for credentials

    final message = Message()
      ..from = Address('rechat@test.com', 'ReChat')
      ..recipients.add(email)
      ..subject = 'You have a friend request!'
      ..html = """
    <h1>Friend Request Invitation</h1>
    <p>You have received a friend request. Open the Chat app to accept or reject the request:</p>
    """;
    try {
      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .single();

      if (userResponse.isEmpty) {
        return false;
      }
      final recipientId = userResponse['id'];
      final senderId = Supabase.instance.client.auth.currentUser!.id;

      // Insert a new friend request
      await Supabase.instance.client.from('friendRequests').insert({
        'senderId': senderId,
        'recipientId': recipientId,
        'status': 'pending',
      });

      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');


      return true;

      // Add your logic here to send a friend request notification

      // final response =
      //     await Supabase.instance.client.from('friend_requests').insert({
      //   'sender_id': Supabase.instance.client.auth.currentUser!.id,
      //   'recipient_id': recipientId,
      // });
    } on MailerException catch (e) {
      print('Message sending failed: ${e.toString()}');
      return false;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  Future<void> removeFriend(String friendId) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      await Supabase.instance.client
          .from('friends')
          .delete()
          .eq('user_id', userId)
          .eq('friend_id', friendId);

      await Supabase.instance.client
          .from('friends')
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', userId);

      notifyListeners();
    } catch (e) {
      print('Error removing friend: $e');
    }
  }
}
