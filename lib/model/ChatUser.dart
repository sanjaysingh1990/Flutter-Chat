import 'package:flutter/animation.dart';

class ChatUser {
  ChatUser({this.createdAt,       //created or updated at
    this.lastMessage,            //last message send or received
    this.userId,                //user id
    this.count,                //total message count
    this.image,               //user image
    this.isBlocked,          //is blocked 0-not blocked 1- is blocked
    this.isOnChatScreen,    //is on chat screen 0- not in chat screen
    this.userName,         //chat user name
    this.animationController});

  final num createdAt;
  String lastMessage;
  final String userId;
  int count;
  final String image;
  final int isBlocked;
  final int isOnChatScreen;
  final String userName;
  final AnimationController animationController;
}