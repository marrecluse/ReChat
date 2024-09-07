




import 'package:flutter/material.dart';
import 'package:my_chat_app/data/profiles-model.dart';
import 'package:my_chat_app/presentation/chat-rooms/chat_rooms.dart';
import 'package:my_chat_app/presentation/friends-screen/friends_screen.dart';
import 'package:my_chat_app/presentation/profile/profile.dart';
import 'package:my_chat_app/presentation/providers/friends-provider.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (context) => HomePage());
  }

  final List<Widget> screens = [
    ChatRooms(),
    FriendsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final _screenIndexProvider = Provider.of<BottomNavigationProvider>(context);
    int currentScreenIndex = _screenIndexProvider.currentIndex;
                final friendsProvider = Provider.of<FriendsProvider>(context);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
        type: BottomNavigationBarType.shifting,  // Use 'fixed' for consistent color behavior
        showSelectedLabels: false,
        elevation: 1.5,
        currentIndex: currentScreenIndex,
        onTap: (value){
          if (currentScreenIndex == 1) {
                friendsProvider.setDefault();

            
          }
          return _screenIndexProvider.updateIndex(value);
        },
        items: [
          BottomNavigationBarItem(
            label: '',
            icon: Icon((currentScreenIndex == 0)
                ? Icons.chat
                : Icons.chat_bubble_outline),
                   backgroundColor: Theme.of(context).primaryColor
          ),
          BottomNavigationBarItem(
            label: '',
            icon: Icon((currentScreenIndex == 1)
                ? Icons.people
                : Icons.people_alt_outlined),
                   backgroundColor: Theme.of(context).primaryColor
          ),
          BottomNavigationBarItem(
            label: '',
            icon: Icon((currentScreenIndex == 2)
                ? Icons.person
                : Icons.person_outline),
                   backgroundColor: Theme.of(context).primaryColor
          ),
        ],
      ),
      body: screens[currentScreenIndex],  // Directly use the screens list
    );
  }
}
