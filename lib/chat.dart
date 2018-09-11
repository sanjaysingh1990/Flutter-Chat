import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gplush_login/Utils/utils.dart';
import 'package:flutter_gplush_login/const.dart';
import 'package:flutter_gplush_login/dialog/DartDialog.dart';
import 'package:flutter_gplush_login/model/ChatKeyModel.dart';
import 'package:flutter_gplush_login/model/ChatMessage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class Chat extends StatelessWidget {
  final String chatUserId;
  Chat({Key key, @required this.chatUserId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new ChatScreen(chatUserId: chatUserId);
  }
}

class ChatScreen extends StatefulWidget {
  final String chatUserId;


  ChatScreen({Key key, @required this.chatUserId})
      : super(key: key);

  @override
  State createState() =>
      new ChatScreenState(
          chatUserId: chatUserId, userId: Utils.instance.userId);
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  ChatScreenState({Key key, @required this.chatUserId, @required this.userId});

  //for user
  String chatUserId;
  String userId;
  bool _userIsOnWindow;
  bool _isUserBlocked;

  List<ChatMessage> _messages = [];
  FirebaseDatabase database;

  DatabaseReference _messagesReference;
  DatabaseReference _chatUsersNodeRef;

  //other

  SharedPreferences prefs;
  File imageFile;
  bool isLoading;
  int limit = 20;
  bool isNoLoadMore = false;

  //callback listener
  var _listener1;
  var _listener2;
  var _listener3;
  var _messageBackup = new Map();


  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();


    isLoading = false;
    database = FirebaseDatabase.instance;
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000); // 10MB cache is enough


    //set
    _messagesReference = FirebaseDatabase.instance.reference()
        .child(userId)
        .child(chatUserId);

    _chatUsersNodeRef = FirebaseDatabase.instance.reference()
        .child('chatUsers');


    //readLocal();
    addListenerToReadMessages();
  }

  @override
  void dispose() {
    super.dispose();
    //dispose listener
    _listener1?.cancel();
    _listener2?.cancel();
    _listener3?.cancel();
  }


//  readLocal() async {
//    prefs = await SharedPreferences.getInstance();
//    id = prefs.getString('id') ?? '';
//    if (id.hashCode <= peerId.hashCode) {
//      groupChatId = '$id-$peerId';
//    } else {
//      groupChatId = '$peerId-$id';
//    }
//
//    setState(() {});
//  }

  Future getImage(int type) async {
    File image;
    if (type == 1) //from gallery
        {
      image = await ImagePicker.pickImage(source: ImageSource.gallery);
    }
    else //from camera
        {
      image = await ImagePicker.pickImage(source: ImageSource.camera);
    }
    if (image != null) {
      setState(() {
        imageFile = image;
        isLoading = true;
      });
    }
    uploadFile();
  }


  Future uploadFile() async {
    String fileName = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);

    Uri downloadUrl = (await uploadTask.future).downloadUrl;
    var imageUrl = downloadUrl.toString();

    setState(() {
      isLoading = false;
    });

    onSendMessage(imageUrl, 1);
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker

    //check user blocked or not
    if (_isUserBlocked) {
      Fluttertoast.showToast(msg: 'You are blocked by the dispensarry. So you can\'t send a message until get unblocked!');
      return;
    }

    else if (content
        .trim()
        .isNotEmpty) {
      textEditingController.clear();

    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
      return;
    }


    String msg = "Photo";
    String imageUrl = null;
    if (type == 0) {
      msg = content;
    }
    else {
      imageUrl = content;
    }

    var key = _messagesReference
        .push()
        .key;
    var currentDateTime = new DateTime.now().millisecondsSinceEpoch;
    var keyNode = {
      'created': currentDateTime,
      'messageId': key,

    };
    var message = {
      'created': currentDateTime,
      'message': msg,
      'messageId': key,
      'recieverId': chatUserId,
      'senderId': userId,
      'image': imageUrl
    };
    DatabaseReference _messageKeyNodeSender = FirebaseDatabase.instance
        .reference()
        .child(userId)
        .child(chatUserId);
    DatabaseReference _messageKeyNodeReceiver = FirebaseDatabase.instance
        .reference()
        .child(chatUserId)
        .child(userId);

    DatabaseReference _message = FirebaseDatabase.instance.reference()
        .child('messages');


    //update current user last message
    _chatUsersNodeRef.child(Utils.instance.userId).child(chatUserId).update(
        {'created': currentDateTime});
    _chatUsersNodeRef.child(Utils.instance.userId).child(chatUserId).update(
        {'lastMessage': msg});


    //update chatting user last message
    _chatUsersNodeRef.child(chatUserId).child(Utils.instance.userId).update(
        {'created': currentDateTime});
    _chatUsersNodeRef.child(chatUserId).child(Utils.instance.userId).update(
        {'lastMessage': msg});

     if(!_userIsOnWindow) {
       _chatUsersNodeRef.child(chatUserId).child(Utils.instance.userId).child('count').once().then((DataSnapshot snapshot) {
         // //print('Connected to second database and read ${snapshot.value}');
         int count=snapshot.value;
         count++;
         //update message count
         _chatUsersNodeRef.child(chatUserId).child(Utils.instance.userId).update(
             {'count': count});


       });
     }

    //add key node message in current user node
    _messageKeyNodeSender.child(key).set(keyNode);
    //add key node to chatting user node
    _messageKeyNodeReceiver.child(key).set(keyNode);

    _message.child(key).set(message);
  }

  Widget buildItem(int index, ChatMessage chatMsg) {
    //print(userId == chatMsg.senderId);
    if (userId == chatMsg.senderId) {
      // Right (my message) user message
      return Column(
        children: <Widget>[
          chatMsg.image == null //show message because image is null
          // Text
              ? Container(
            child: InkWell(
              onLongPress: () {
                //print(index);
                //print(_messages[index].message);
                _showDialog(_messages[index], index);
              },
              child: Text(
                chatMsg.message,
                style: TextStyle(color: primaryColor),
              ),
            ),
            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            width: 200.0,
            decoration: BoxDecoration(
                color: greyColor2, borderRadius: BorderRadius.circular(8.0)),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight(index)
                    ? 5.0 : 10.0, right: 10.0),
          )
              :
          // Image
          Container(
            child: Material(
              child: CachedNetworkImage(
                placeholder: Container(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                  width: 200.0,
                  height: 200.0,
                  padding: EdgeInsets.all(70.0),
                  decoration: BoxDecoration(
                    color: greyColor2,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                ),
                errorWidget: Material(
                  child: Image.asset(
                    'images/img_not_available.jpeg',
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
                imageUrl: chatMsg.image,
                width: 200.0,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight
                  (index) ? 5.0 : 10.0, right:
            10.0),
          ),

          // Time
          isLastMessageRight(index)
              ?
          Container(
            child: Text(
              Utils.instance.getFormatedTime(chatMsg.createdAt)
              ,
              style: TextStyle
                (color: greyColor,
                  fontSize: 12.0,
                  fontStyle
                      : FontStyle.italic),
            ),
            margin:
            EdgeInsets
                .
            only
              (
                right
                    :
                10.0
                ,
                bottom
                    :
                10.0
            )
            ,
          )
              :
          Container
            (
          )


        ],
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment
            :
        CrossAxisAlignment
            .
        end
        ,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                  child: CachedNetworkImage(
                    placeholder: Container(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(10.0),
                    ),
                    imageUrl: "https://i.imgur.com/BoN9kdC.png",
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(18.0),
                  ),
                )
                    : Container(width: 35.0),
                chatMsg.image == null
                    ? Container(
                  child: Text(
                    chatMsg.message,
                    style: TextStyle(color: Colors.white),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(color: primaryColor,
                      borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    : Container(
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder: Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                        width: 200.0,
                        height: 200.0,
                        padding: EdgeInsets.all(70.0),
                        decoration: BoxDecoration(
                          color: greyColor2,
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                      ),
                      errorWidget: Material(
                        child: Image.asset(
                          'images/img_not_available.jpeg',
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                      imageUrl: chatMsg.image,
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                )
//                        : Container(
//                            child: new Image.asset(
//                              'images/${document['content']}.gif',
//                              width: 100.0,
//                              height: 100.0,
//                              fit: BoxFit.cover,
//                            ),
//                            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
//                          ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
              child: Text(
                Utils.instance.getFormatedTime(chatMsg.createdAt),
                style: TextStyle(color: greyColor,
                    fontSize: 12.0,
                    fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
            )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
        _messages[index].senderId == chatUserId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
        _messages[index].senderId == userId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(
            'CHAT',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            // action button
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red,),
              onPressed: () {
                _choice();
              },
            ),

          ],
          automaticallyImplyLeading: true,
          centerTitle: true,

        ),

        body:

        new Stack(
          children: <Widget>[
        Column(
          children: <Widget>[
            // List of messages
            buildListMessage(),

            // Input content
            buildInput(),
          ],
        ),

        // Loading
        buildLoading()
          ],
        )

    );
  }


  void _choice() {
    //show dialog before deleting message
    new DartDialog().showWarningDialogDeleteChat(
        _scaffoldKey.currentContext, deleteChat);
  }

  VoidCallback deleteChat() {
    setState(() {
      isLoading = true;
    });
    FirebaseDatabase.instance.reference()
        .child(Utils.instance.userId)
        .child(chatUserId).remove();



    //update current user last message nad time to 0
    _chatUsersNodeRef.child(Utils.instance.userId).child(chatUserId).update(
        {'created': 0});
    _chatUsersNodeRef.child(Utils.instance.userId).child(chatUserId).update(
        {'lastMessage': ""});

    setState(() {
      _messages.clear();
      isLoading = false;
    });
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border: new Border(
              top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(new Color(0xfff5a623))),
        ),
        color: Colors.white.withOpacity(0.8),
      )
          : _messages.length!=0?Container():new Center(
        child: new Text("start your conversation!"),
      ),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: _showDialogImagePicker,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
//          Material(
//            child: new Container(
//              margin: new EdgeInsets.symmetric(horizontal: 1.0),
//              child: new IconButton(
//                icon: new Icon(Icons.face),
//                onPressed: getSticker,
//                color: primaryColor,
//              ),
//            ),
//            color: Colors.white,
//          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(
              top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return new Flexible(
      child: new ListView.builder(
        controller: listScrollController,
        padding: new EdgeInsets.all(8.0),
        reverse: true,
        itemBuilder: (_, int index) =>
            buildItem(index, _messages[index]),
        itemCount: _messages.length,

      ),);
  }

  void loadMore(String lastid) {
    if (isNoLoadMore) {
      return; //no data for load more
    }
    limit = limit + 10;
    setState(() {
      isLoading = true;
    });
    print("limit:$limit");
    //on child change
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _messagesReference.orderByKey().limitToLast(limit).once().then((
          DataSnapshot snapshot) {
        print("data received ${snapshot.value}");
        Map<dynamic, dynamic> fridgesDs = snapshot.value;
        List<dynamic> list = fridgesDs.values.toList()
          ..sort((a, b) => b['created'].compareTo(a['created']));

        for (var value in list) {
          var key = value["messageId"];
          print("lm :$key");
          bool isInside = false;
          if (!_messageBackup.containsKey(key)) {
            isInside = true;
            _messageBackup[key] = "chat";
            setState(() {
              getMessage(key, true);
            });
          }

          if (isInside) {
            isNoLoadMore = false; //data available for load more
          }
          else {
            isNoLoadMore = true; //data not available for load more
          }
        }
//        fridgesDs.forEach((key, value) {
//
//
//        });

        setState(() {
          isLoading = false;
        });
      });
    });
  }

  void addListenerToReadMessages() {
    setState(() {
      isLoading = true;
    });
    //on child change
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _listener1 = _messagesReference
          .limitToLast(limit)
          .onChildAdded
          .listen((Event event) {

        var val = event.snapshot.value;
        var _messagekey = val['messageId'];
        print(_messagekey);
        _messageBackup[_messagekey] = "message";
        getMessage(_messagekey, false);
      });

      setState(() {
        isLoading = false;
      });

    });

    //on chat screen user
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _listener2 = _chatUsersNodeRef
          .child(chatUserId)
          .child(userId)
          .child("isOnChatScreen")
          .onValue
          .listen((Event event) {
        var val = event.snapshot.value;
        _userIsOnWindow = val == 1 ? true : false;
        //print("is user onine :$val");
      });
    });


    //on check for block condition
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _listener3 = _chatUsersNodeRef
          .child(chatUserId)
          .child(userId)
          .child("isBlocked")
          .onValue
          .listen((Event event) {
        var val = event.snapshot.value;
        _isUserBlocked = val == 1 ? true : false;
        print("is user blocked :$val");
      });
    });

//    FirebaseAuth.instance.signInAnonymously().then((user) {
//      _messagesReference.child("messageId").orderByKey().once().then((DataSnapshot snapshot) {
//
//        //print('Connected to second database and read ${snapshot.value}');
//      });
//    });


    listScrollController.addListener(
            () {
          double maxScroll = listScrollController.position.maxScrollExtent;
          double currentScroll = listScrollController.position.pixels;
          double delta = 200.0; // or something else..
          //print(maxScroll.toString() + currentScroll.toString());
          if (maxScroll - currentScroll <=
              delta) { // whatever you determine here
            // //print("max scroll:$maxScroll, current scroll:$currentScroll");
            if (maxScroll == currentScroll) {
              print("reached top");
              loadMore("");
            }
          }
        }
    );
  }

  Future<ChatKeyModel> getMessage(String messageKey, bool loadmore) async {
    Completer<ChatKeyModel> completer = new Completer<ChatKeyModel>();

    setState(() {
      isLoading = false;
    });

    FirebaseDatabase.instance
        .reference()
        .child("messages")
        .child(messageKey)
        .once()
        .then((DataSnapshot snapshot) {
      var val = snapshot.value;

      _addMessage(
          created: val['created'],
          msg: val['message'],
          msgId: val['messageId'],
          recId: val['recieverId'],
          sendId: val['senderId'],
          imageUrl: val['image'],
          isLoadmore: loadmore);
    });

    return completer.future;
  }

  void _addMessage({
    num created,
    String msg,
    String msgId,
    String recId,
    String sendId,
    String imageUrl,
    bool isLoadmore

  }) {
    var animationController = new AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );
    print("read message $msg");
    var message = new ChatMessage(
        createdAt: created,
        message: msg,
        messageId: msgId,
        receiverId: recId,
        senderId: sendId,
        image: imageUrl,
        animationController: animationController);
    setState(() {
      if (!isLoadmore)
        _messages.insert(0, message);
      else
        _messages.add(message);

    });

    if (imageUrl != null) {
      NetworkImage image = new NetworkImage(imageUrl);
      image
          .resolve(createLocalImageConfiguration(context))
          .addListener((_, __) {
        animationController?.forward();
      });
    } else {
      animationController?.forward();
    }
  }


  //show dialog for choose images from
// user defined function
  void _showDialog(ChatMessage chatMsg, int index) {
    // flutter defined function

    final myController = TextEditingController();
    myController.text = chatMsg.message;
    showDialog(

      context: _scaffoldKey.currentContext,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Update Message"),
          content: new Container(
            height: 80.0,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                new TextField(

                  controller: myController,

                ),


              ]
              ,
            ),

          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("UPDATE"),
              onPressed: () {
                //print(chatMsg.messageId);
                String msg = myController.text;

                var currentDateTime = new DateTime.now().millisecondsSinceEpoch;
                var newMsg = {
                  'created': currentDateTime,
                  'message': msg,
                  'messageId': chatMsg.messageId,
                  'recieverId': chatUserId,
                  'senderId': userId,
                  'image': chatMsg.image
                };
                DatabaseReference _message = FirebaseDatabase.instance
                    .reference()
                    .child('messages');
                _message.child(chatMsg.messageId).set(newMsg);
                setState(() {
                  _messages[index].message = msg;
                  // _messages.removeAt(index);
                  //  _messages.insert(index, element);

                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  //show dialog for choose images from
// user defined function
  void _showDialogImagePicker() {
    // flutter defined function
    showDialog(

      context: _scaffoldKey.currentContext,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Choose Image"),
          content: new Container(
            height: 100.0,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    getImage(2); //from camera
                    Navigator.pop(_scaffoldKey.currentContext);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        new Icon(
                            Icons.camera,
                            color: Colors.orangeAccent,
                            size: 24.0),

                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: new Text(
                            "Camera",
                            style: new TextStyle(fontSize: 17.0,
                                color: const Color(0xFF000000),
                                fontWeight: FontWeight.w500,
                                fontFamily: "Roboto"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                new Divider(
                  color: Colors.grey,
                ),
                InkWell(

                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        new Icon(
                            Icons.image,
                            color: Colors.orangeAccent,
                            size: 24.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: new Text(
                            "Gallery",
                            style: new TextStyle(fontSize: 17.0,
                                color: const Color(0xFF000000),
                                fontWeight: FontWeight.w500,
                                fontFamily: "Roboto"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () { //close dialog
                    getImage(1); //from gallery
                    Navigator.pop(_scaffoldKey.currentContext);
                  },
                ),
              ]
              ,
            ),

          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


}
