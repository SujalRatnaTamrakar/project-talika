import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talika/components/helpers/adState.dart';
import 'package:talika/components/helpers/notificationsHelper.dart';
import 'package:talika/screens/OnBoardingScreen.dart';
import 'package:talika/screens/SplashScreen.dart';
import 'package:talika/todolist_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'components/controllers/CategoryController.dart';
import 'components/controllers/NavigationController.dart';
import 'components/controllers/TaskController.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var prefs = await SharedPreferences.getInstance();
  var boolKey = 'isFirstTime';
  bool isFirstTime = prefs.getBool(boolKey) ?? true;
  MobileAds.instance.initialize();
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
            channelKey: 'task_reminder_channel',
            channelName: 'Task Reminder Notifications',
            channelDescription: 'Notification channel for tasks reminder',
            defaultColor: secondaryColor,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            locked: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.white)
      ],
      debug: true);
  AwesomeNotifications()
      .actionStream
      .listen((ReceivedNotification receivedNotification) {
    Navigator.of(homeKey.currentContext as BuildContext)
        .pushNamed(ToDoListScreen.id);
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
      (value) => runApp(
          App(prefs: prefs, boolKey: boolKey, isFirstTime: isFirstTime)));
}

class App extends StatefulWidget {
  final SharedPreferences prefs;
  final String boolKey;
  final bool isFirstTime;
  const App(
      {Key? key,
      required this.prefs,
      required this.boolKey,
      required this.isFirstTime})
      : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talika',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white),
        canvasColor: secondaryColor,
      ),
      home: SplashScreen(
          prefs: widget.prefs,
          boolKey: widget.boolKey,
          isFirstTime: widget.isFirstTime),
      routes: {
        OnBoardingScreen.id: (context) => const OnBoardingScreen(),
        ToDoListScreen.id: (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (context) => TaskController(),
                ),
                ChangeNotifierProvider(
                  create: (context) => CategoryController(),
                ),
                ChangeNotifierProvider(
                  create: (context) => NavigationController(),
                ),
              ],
              child: const ToDoListScreen(),
            ),
      },
    );
  }
}
