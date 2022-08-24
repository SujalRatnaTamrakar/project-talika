import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talika/constants.dart';
import 'package:talika/screens/OnBoardingScreen.dart';
import 'package:talika/todolist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../components/helpers/notificationsHelper.dart';

final homeKey = GlobalKey<_SplashScreenState>();

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final String boolKey;
  final bool isFirstTime;
  SplashScreen(
      {Key? key,
      required this.prefs,
      required this.boolKey,
      required this.isFirstTime})
      : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 3),
        () => widget.isFirstTime
            ? Navigator.pushReplacementNamed(context, OnBoardingScreen.id)
            : Navigator.pushReplacementNamed(context, ToDoListScreen.id));
  }

  @override
  Widget build(BuildContext context) {
    widget.prefs.setBool(widget.boolKey, false);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/logo.png",
              width: 200,
              height: 200,
            ),
            const Text(
              "Talika",
              style: TextStyle(fontSize: 50),
            )
          ],
        ),
      ),
    );
  }
}
