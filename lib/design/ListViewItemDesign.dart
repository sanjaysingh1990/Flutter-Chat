import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gplush_login/Utils/utils.dart';
import 'package:flutter_gplush_login/chat.dart';
import 'package:flutter_gplush_login/model/ChatUser.dart';
import 'package:flutter_gplush_login/viewscreen/ChatUser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListViewItemDesign {


  //update count to zero
  void updateUnreadMessageCount(String toUserId)  {

     print("userid:${Utils.instance.userId}");
    //update count value to 0
    FirebaseDatabase.instance.reference()
        .child('chatUsers').child(Utils.instance.userId).child(toUserId).update({
      'count': 0
    });
  }

  //for chat user item design
  Widget buildItemChatUser(int index, ChatUser user) {
    return InkWell(
      onTap: () {
        //update message count read
        if (user.count > 0) {
          updateUnreadMessageCount(user.userId);
        }
        Navigator.push(
          scaffoldKey.currentContext,
          MaterialPageRoute(builder: (context) =>
          new Chat(
              chatUserId: user.userId)),
        );
      },
      child: Card(
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //user circular image
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                          fit: BoxFit.fill,
                          image: new NetworkImage(
                              user.image == null
                                  ? 'https://i.imgur.com/BoN9kdC.png'
                                  : user.image)
                      )
                  )),
            ), //user circular image

            //user information
            new Expanded(child:
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  //user name
                  new Text(
                    "${user.userName}",
                    style: new TextStyle(fontSize: 16.0,
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w500,
                        fontFamily: "Roboto"),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ), //user name

                  //user name
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                    child: new Text(
                      user.lastMessage.isNotEmpty?"${user.lastMessage}":"No message",
                      style: new TextStyle(fontSize: 12.0,
                          color: const Color(0xFF000000),
                          fontWeight: FontWeight.w300,
                          fontFamily: "Roboto"),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ), //user name
                ],
              ),
            ) //user informaiton
            ),

            //show time
            Padding(
              padding: const EdgeInsets.only(right: 6.0, top: 8.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[

                  //last message time
                  new Text(
                    "${Utils.instance.getFormatedTime(user.createdAt)}",
                    style: new TextStyle(fontSize: 13.0,
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w400,
                        fontFamily: "Roboto"),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ), //show time


                  //show count
                  user.count > 0 ? //check if unread message count is 0 or not
                  //user circular image
                  new Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: new Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: new BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: new Text(
                                user.count > 99 ? "99+" : "${user.count}",
                                style: new TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.white

                                ),),
                            ),
                          )))
                  //user circular image
                      :
                  new Container()

                ],
              ),
            )


          ],

        ),

      ),
    ); //end card here
  }


}