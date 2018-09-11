import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gplush_login/Utils/utils.dart';
import 'package:flutter_gplush_login/const.dart';
import 'package:flutter_gplush_login/design/ListViewItemDesign.dart';
import 'package:flutter_gplush_login/model/ChatUser.dart';

GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

class ChatUserScreen extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text(
          'CHAT USERS',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: new ChatScreen(

      ),
    );
  }

}

class ChatScreen extends StatefulWidget {

  @override
  State createState() =>
      new ChatScreenState();
}


class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {

  bool _isLoading = true;
  final ScrollController _listScrollController = new ScrollController();
  List<ChatUser> _chatUsers = [];
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference _chatUsersNodeRef;

  DatabaseReference _chatUserReference = FirebaseDatabase.instance.reference()
      .child('chatUsers');


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print(Utils.instance.userId);
    _chatUsersNodeRef = FirebaseDatabase.instance.reference()
        .child('chatUsers').child(Utils.instance.userId);

    addListenerToReadMessages();

    // _addUser("2");
  }


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return

      Stack(children: <Widget>[
        _buildListMessage(),
        buildLoading()

      ]);
  }


  Widget buildLoading() {
    return Positioned(
        child: _isLoading
            ? Container(
          child: Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    new Color(0xfff5a623))),
          ),
          color: Colors.white.withOpacity(0.8),
        )
            : Container()
    );
  }

  Widget _buildListMessage() {
    return new ListView.builder(
      controller: _listScrollController,
      padding: new EdgeInsets.all(8.0),
      itemBuilder: (_, int index) =>
          new ListViewItemDesign().buildItemChatUser(index, _chatUsers[index]),
      itemCount: _chatUsers.length,

    );
  }


  void addListenerToReadMessages() {
    var animationController = new AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );

    FirebaseAuth.instance.signInAnonymously().then((user) {
      _chatUsersNodeRef.onChildAdded.listen((Event event) {
        var val = event.snapshot.value;


        //add chat user in list
        var chatUser = new ChatUser(
            createdAt: val['created'],
            lastMessage: val['lastMessage'],
            userId: val['userId'],
            count: val['count'],
            image: val['image'],
            isBlocked: val['isBlocked'],
            isOnChatScreen: val['isOnChatScreen'],
            userName: val['userName'],
            animationController: animationController

        );
        setState(() {
           _isLoading=false;
          //add user in list and update it
          _chatUsers.insert(0, chatUser);
        });
      });
    });

    //listener to check for updated message and unread message count
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _chatUsersNodeRef.onChildChanged.listen((Event event) {
        var val = event.snapshot.value;
        var userId = val['userId'];
        print('chatid:$userId');
        for (var index = 0; index < _chatUsers.length; index++) {
          var user = _chatUsers[index];
          if (user.userId == userId) {
            //update last message
            setState(() {
              _chatUsers[index].lastMessage = val['lastMessage'];
              _chatUsers[index].count = val['count'];
              _chatUsers[index].createdAt = val['created'];
            });
          }
        }
      });
    });

    //remove from list if user deleted from friend list
    //listener to check for updated message and unread message count
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _chatUsersNodeRef.onChildRemoved.listen((Event event) {
        var val = event.snapshot.value;
        var userId = val['userId'];

        for (var index = 0; index < _chatUsers.length; index++) {
          var user = _chatUsers[index];
          if (user.userId == userId) {
            //update last message
            setState(() {
              _chatUsers.removeAt(index);
            });
          }
        }
      });
    });
  }


  void _addUser(String chatUserId) {
    String msg="";
    var currentDateTime = 0;//new DateTime.now().millisecondsSinceEpoch;

    var ToChatUser = {
      'created': currentDateTime,
      'lastMessage': msg,
      'userId': Utils.instance.userId,
      'count': 0,
      'image': 'https://i.imgur.com/BoN9kdC.png',
      'isBlocked':0,
      'isOnChatScreen':0,
      'userName':'Mukesh Khulve'
    };

    var ChatUser = {
      'created': currentDateTime,
      'lastMessage': msg,
      'userId': chatUserId,
      'count': 0,
      'image': 'https://i.imgur.com/BoN9kdC.png',
      'isBlocked':0,
      'isOnChatScreen':0,
      'userName':'Sanjay Singh Bisht'
    };

    //create user
    _chatUserReference.child(Utils.instance.userId).child(chatUserId).set(ChatUser);
    _chatUserReference.child(chatUserId).child(Utils.instance.userId).set(ToChatUser);
  }

}


