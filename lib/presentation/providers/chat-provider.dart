import 'package:flutter/material.dart';
import 'package:my_chat_app/data/message-model.dart';
import 'package:my_chat_app/utils/constants/constants.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> fetchMessages(String chatroomId) async {
    _isLoading = true;
    notifyListeners();

    // try {
    //   // Fetch messages from the database
    //   final response = await supabase
    //       .from('messages')
    //       .select()
    //       .eq('chatroom_id', chatroomId)
    //       .order('created_at', ascending: true); // Example ordering by creation time

    //   _messages = (response as List).map((item) => Message.fromMap(item)).toList();
    // } catch (error) {
    //   print('Error fetching messages: $error');
    //   // Handle error appropriately
    // } finally {
    //   _isLoading = false;
    //   notifyListeners();
    // }
  }

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }
}
