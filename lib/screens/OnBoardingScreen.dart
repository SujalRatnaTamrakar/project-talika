import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talika/todolist_screen.dart';

class OnBoardingScreen extends StatelessWidget {
  static const id = "OnBoardingScreen";
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    buildImage(String path) => Center(
          child: SvgPicture.asset(
            path,
            width: MediaQuery.of(context).size.width,
          ),
        );

    PageDecoration getPageDecoration() => PageDecoration(
        titleTextStyle:
            const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        bodyTextStyle: const TextStyle(fontSize: 20),
        bodyPadding: const EdgeInsets.all(16).copyWith(bottom: 0),
        imagePadding: const EdgeInsets.all(24));

    openHomePage() =>
        Navigator.of(context).pushReplacementNamed(ToDoListScreen.id);

    return SafeArea(
        child: IntroductionScreen(
      showDoneButton: true,
      done: const Text("START >>"),
      onDone: () => {openHomePage()},
      next: const Text("NEXT >"),
      showSkipButton: true,
      skip: const Text("SKIP"),
      onSkip: () => {openHomePage()},
      pages: [
        PageViewModel(
          title: "The only To-Do List you'll ever need",
          body: "Keep a record of all your to-do tasks!",
          image: buildImage("assets/svgs/add_task.svg"),
          decoration: getPageDecoration(),
        ),
        PageViewModel(
          title: "Custom categories",
          body: "Fully customizable task categorization!",
          image: buildImage("assets/svgs/add_categories.svg"),
          decoration: getPageDecoration(),
        ),
        PageViewModel(
          title: "Notifications",
          body: "Turn on notifications for your important tasks!",
          image: buildImage("assets/svgs/push_notifications.svg"),
          decoration: getPageDecoration(),
        ),
      ],
    ));
  }
}
