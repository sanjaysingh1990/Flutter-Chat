import 'dart:async';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils
{
  static final Utils _singleton = new Utils._internal();
  var userId;
  Utils._internal();
  static Utils get instance => _singleton;




  //get last message time
    String getFormatedTime(num milliseconds)
   {
    return DateFormat.jm()
         .format(DateTime.fromMillisecondsSinceEpoch(
         int.parse(milliseconds.toString())));
   }

   Future loadSharedPreference()
   async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
     userId=prefs.getString("id");

   }
}