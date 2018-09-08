import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gplush_login/Utils/utils.dart';

import 'package:flutter_gplush_login/const.dart';
import 'package:flutter_gplush_login/main.dart';
import 'package:flutter_gplush_login/viewscreen/ChatUser.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:http/http.dart" as http;

GoogleSignIn _googleSignIn = new GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);
void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',
      theme: new ThemeData(
        primaryColor: themeColor,
      ),
      home: LoginScreen(title: 'CHAT DEMO'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {

  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => new LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  GoogleSignInAccount _currentUser;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;
  bool isLoading = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    //load shared preference value in util class
    Utils.instance.loadSharedPreference();
    isSignedIn();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      _saveDataToCache();
      setState(() {
        _currentUser = account;
        print(_currentUser.displayName+_currentUser.email);
        print("called2");


      });

    });
   // _googleSignIn.signInSilently();

  }

  Future<Null> _handleSignIn() async {
    print("called");
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  void _saveDataToCache() async
  {
    print("called");
    prefs = await SharedPreferences.getInstance();

    await prefs.setString('id', _currentUser.id);
    await prefs.setString('nickname', _currentUser.displayName);
    await prefs.setString('photoUrl', _currentUser.photoUrl);

    Fluttertoast.showToast(msg: "Sign in success");


    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => new ChatUserScreen(

      )),
    );

  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    isLoggedIn = await _googleSignIn.isSignedIn();
    if (isLoggedIn) {
    //  Fluttertoast.showToast(msg: "Sign in success");


      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => new ChatUserScreen(

        )),
      );

    }



    this.setState(() {
      isLoading = false;
    });
  }



//  Future<Null> handleSignIn() async {
//    prefs = await SharedPreferences.getInstance();
//
//    this.setState(() {
//      isLoading = true;
//    });
//
//    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
//    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//    FirebaseUser firebaseUser = await firebaseAuth.signInWithGoogle(
//      accessToken: googleAuth.accessToken,
//      idToken: googleAuth.idToken,
//    );
//    if (firebaseUser != null) {
//      // Check is already sign up
//      final QuerySnapshot result =
//      await Firestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).getDocuments();
//      final List<DocumentSnapshot> documents = result.documents;
//      if (documents.length == 0) {
//        // Update data to server if new user
//        Firestore.instance.collection('users').document(firebaseUser.uid).setData(
//            {'nickname': firebaseUser.displayName, 'photoUrl': firebaseUser.photoUrl, 'id': firebaseUser.uid});
//
//        // Write data to local
//        currentUser = firebaseUser;
//        await prefs.setString('id', currentUser.uid);
//        await prefs.setString('nickname', currentUser.displayName);
//        await prefs.setString('photoUrl', currentUser.photoUrl);
//      } else {
//        // Write data to local
//        await prefs.setString('id', documents[0]['id']);
//        await prefs.setString('nickname', documents[0]['nickname']);
//        await prefs.setString('photoUrl', documents[0]['photoUrl']);
//        await prefs.setString('aboutMe', documents[0]['aboutMe']);
//      }
//      Fluttertoast.showToast(msg: "Sign in success");
//      this.setState(() {
//        isLoading = false;
//      });
//
//      Navigator.push(
//        context,
//        MaterialPageRoute(
//            builder: (context) =>
//                MainScreen(
//                  currentUserId: firebaseUser.uid,
//                )),
//      );
//    } else {
//      Fluttertoast.showToast(msg: "Sign in fail");
//      this.setState(() {
//        isLoading = false;
//      });
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: FlatButton(
                  onPressed: _handleSignIn,
                  child: Text(
                    'SIGN IN WITH GOOGLE',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  color: Color(0xffdd4b39),
                  highlightColor: Color(0xffff7f7f),
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
                color: Colors.white.withOpacity(0.8),
              )
                  : Container(),
            ),
          ],
        ));
  }
}
