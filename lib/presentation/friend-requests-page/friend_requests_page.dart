import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_chat_app/data/user-model.dart';
import 'package:my_chat_app/presentation/friends-screen/friends_screen.dart';
import 'package:my_chat_app/presentation/providers/friends-provider.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:provider/provider.dart';

class FriendRequestsPage extends StatefulWidget {
  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => FriendRequestsPage());
  }

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  Widget slideLeftBackground() {
    return Container(
      color: Colors.red,
      child: const Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            Text(
              " Reject",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendsProvider.getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2,));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching friend requests'));
        }
        final requests = snapshot.data ?? [];

        if (!snapshot.hasData || requests.isEmpty) {
          return const Center(
            child: Text('No requests'),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final senderId = request['senderId'] ?? '';
            final requestId = request['id'] ?? '';

            return FutureBuilder<UserModel?>(
                future: friendsProvider.fetchDetails(senderId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2,));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text('No details found'),
                    );
                  }

                  final sender = snapshot.data!;
                  return Dismissible(
                    key: Key(
                        requestId.toString()), // Unique key for each request
                    direction: DismissDirection.endToStart,
                    background:
                        slideLeftBackground(), // Disable swipe for dismissal

                    onDismissed: (direction) {
                      // Optionally, remove from the list once dismissed
                      requests.removeAt(index);
                      friendsProvider.rejectFriendRequest(requestId);
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(sender.profile_url),
                      ),

                      title: Text(sender.name),
                      subtitle: Text('${sender.email}'), // Adjust as needed
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                friendsProvider.acceptFriendRequest(requestId);
                                setState(() {
                                  requests.removeAt(index);
                                });
                              },
                              child: Text(
                                'Accept',
                              ))
                          // IconButton(
                          //   icon: const FaIcon(FontAwesomeIcons.check),
                          //   onPressed: () {
                          //     // acceptFriendRequest(request['id']);
                          //   },
                          // ),
                          // IconButton(
                          //   icon: const Icon(Icons.close),
                          //   onPressed: () {
                          //     // rejectFriendRequest(request['id']);
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  );
                });
          },
        );
      },
    );
  }
}
