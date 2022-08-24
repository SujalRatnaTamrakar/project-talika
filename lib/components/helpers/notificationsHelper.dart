import 'dart:math';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talika/constants.dart';

import '../models/Category.dart';
import '../models/Task.dart';
import 'databaseHelper.dart';

Future<void> createTaskReminderNotification(
    DateTime dateTime, Task task, int notificationId) async {
  String title = task.title;
  String date = DateFormat("hh:mm aaa").format(dateTime).toString();
  String category_name = task.category_name;
  dateTime = dateTime.subtract(const Duration(hours: 1));
  final cat = await DatabaseHelper.instance.getCategory(task.category + 1);
  Category category = Category.fromMap(cat[0]);
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: notificationId,
          color: Color(category.category_color),
          backgroundColor: Color(category.category_color),
          channelKey: 'task_reminder_channel',
          title:
              '${Emojis.office_memo} [$category_name] Did you complete your task?',
          body: 'Your task - $title - was scheduled to be completed at $date',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder),
      schedule: NotificationCalendar(
          year: dateTime.year,
          month: dateTime.month,
          day: dateTime.day,
          hour: dateTime.hour,
          minute: dateTime.minute,
          second: dateTime.second,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier()));
}

// Future<void> cancelScheduledNotifications() async {
//   await AwesomeNotifications().cancel(id);
// }

createUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

Future<bool> requestBasicPermissionToSendNotifications(
    BuildContext context) async {
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: bgColor,
              title: const Text('Get Notified!',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/notifications.svg',
                    height: MediaQuery.of(context).size.height * 0.3,
                    fit: BoxFit.fitWidth,
                  ),
                  const Text(
                    'Allow the app to send you beautiful notifications!',
                    maxLines: 4,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Later',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    )),
                TextButton(
                  onPressed: () async {
                    isAllowed = await AwesomeNotifications()
                        .requestPermissionToSendNotifications();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ));
  }
  return isAllowed;
}

Future<List<NotificationPermission>> requestUserPermissions(
    BuildContext context,
    {
// if you only intends to request the permissions until app level, set the channelKey value to null
    required String? channelKey,
    required List<NotificationPermission> permissionList}) async {
// Check if the basic permission was conceived by the user
  if (!await requestBasicPermissionToSendNotifications(context)) return [];

// Check which of the permissions you need are allowed at this time
  List<NotificationPermission> permissionsAllowed = await AwesomeNotifications()
      .checkPermissionList(channelKey: channelKey, permissions: permissionList);

// If all permissions are allowed, there is nothing to do
  if (permissionsAllowed.length == permissionList.length) {
    return permissionsAllowed;
  }

// Refresh the permission list with only the disallowed permissions
  List<NotificationPermission> permissionsNeeded =
      permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

// Check if some of the permissions needed request user's intervention to be enabled
  List<NotificationPermission> lockedPermissions = await AwesomeNotifications()
      .shouldShowRationaleToRequest(
          channelKey: channelKey, permissions: permissionsNeeded);

// If there is no permitions depending of user's intervention, so request it directly
  if (lockedPermissions.isEmpty) {
// Request the permission through native resources.
    await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: channelKey, permissions: permissionsNeeded);

// After the user come back, check if the permissions has successfully enabled
    permissionsAllowed = await AwesomeNotifications().checkPermissionList(
        channelKey: channelKey, permissions: permissionsNeeded);
  } else {
// If you need to show a rationale to educate the user to conceed the permission, show it
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: bgColor,
              title: const Text(
                'Talika - To-Do List needs your permission',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/notifications.svg',
                    height: MediaQuery.of(context).size.height * 0.3,
                    fit: BoxFit.fitWidth,
                  ),
                  const Text(
                    'To receive notifications, you need to enable the notification permissions',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Deny',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    )),
                TextButton(
                  onPressed: () async {
// Request the permission through native resources. Only one page redirection is done at this point.
                    await AwesomeNotifications()
                        .requestPermissionToSendNotifications(
                            channelKey: channelKey,
                            permissions: lockedPermissions);

// After the user come back, check if the permissions has successfully enabled
                    permissionsAllowed = await AwesomeNotifications()
                        .checkPermissionList(
                            channelKey: channelKey,
                            permissions: lockedPermissions);

                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ));
  }

// Return the updated list of allowed permissions
  return permissionsAllowed;
}
