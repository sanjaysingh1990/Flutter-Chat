import 'package:flutter/animation.dart';

class ChatMessage {
  ChatMessage({this.createdAt,
    this.messageId,
    this.message,
    this.receiverId,
    this.senderId,
    this.image,
    this.animationController});

  final num createdAt;
   String message;
  final String messageId;
  final String receiverId;
  final String senderId;
  final String image;
  final AnimationController animationController;
}