import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';

final _fireStore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController textEditingController = TextEditingController();
  User firebaseUser;
  String chatText;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (null != _auth) {
      firebaseUser = _auth.currentUser;
      print(firebaseUser.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStreamWidget(
              currentUser: firebaseUser.email,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textEditingController,
                      onSubmitted: (value) {
                        chatText = value;
                        textEditingController.clear();
                        _fireStore.collection('messages').add(
                            {'sender': firebaseUser.email, 'text': chatText});
                      },
                      onChanged: (value) {
                        chatText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      textEditingController.clear();
                      _fireStore.collection('messages').add(
                          {'sender': firebaseUser.email, 'text': chatText});
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStreamWidget extends StatelessWidget {
  MessageStreamWidget({this.currentUser});

  final String currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      builder: (context, streamData) {
        if (!streamData.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        List<MessageBubble> messageBubbleListWidget = [];
        for (QueryDocumentSnapshot message in streamData.data.docs.reversed) {
          var text = message.get('text');
          var sender = message.get('sender');
          messageBubbleListWidget.add(MessageBubble(
              text: text, sender: sender, isMe: sender == currentUser));
        }
        return Expanded(
          child: ListView(
            reverse: true,
            children: messageBubbleListWidget,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isMe});

  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          sender,
          style: TextStyle(fontSize: 10.0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
          child: Material(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 30 : 0),
                  topRight: Radius.circular(isMe ? 0 : 30),
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30)),
              elevation: 10,
              color: isMe ? Colors.lightBlueAccent : Colors.white,
              textStyle: TextStyle(color: isMe ? Colors.white : Colors.black),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('$text'),
              )),
        ),
      ],
    );
  }
}
