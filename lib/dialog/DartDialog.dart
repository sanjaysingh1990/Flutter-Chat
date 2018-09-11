import 'package:flutter/material.dart';

class DartDialog {

  //show dialog for choose images from
// user defined function
  void showWarningDialogDeleteChat(BuildContext context,VoidCallback callback) {
    // flutter defined function

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          content: new Container(
            height: 100.0,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                Center(
                  child: new Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 48.0),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: new Text(
                    "Are you sure want to delete this conversation?",
                    style: new TextStyle(fontSize: 15.0,
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w400,
                        fontFamily: "Roboto"),
                  ),
                ),


              ]
              ,
            ),

          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("DELETE"),
              onPressed: () {
                callback();
                Navigator.of(context).pop();
              },
            ),

            new FlatButton(
              child: new Text("CANCEL"),
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

