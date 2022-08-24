import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bulleted_list/bulleted_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../controllers/CategoryController.dart';
import '../controllers/TaskController.dart';
import '../helpers/databaseHelper.dart';
import '../helpers/notificationsHelper.dart';
import '../models/Category.dart';
import '../models/Task.dart';

class TaskCard extends StatefulWidget {
  final task;
  int cardColor;
  TaskCard({Key? key, this.task, required this.cardColor}) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Provider.of<TaskController>(context, listen: false);
    final categoryController =
        Provider.of<CategoryController>(context, listen: false);
    return Slidable(
      key: const ValueKey(0),
      endActionPane: ActionPane(
        extentRatio: 0.35,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
              icon: widget.task.isCompleted == 0
                  ? Icons.check_circle_outline
                  : Icons.close_outlined,
              backgroundColor: widget.task.isCompleted == 0
                  ? Colors.green
                  : Colors.redAccent,
              onPressed: (context) async {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Are you sure?"),
                        content: widget.task.isCompleted == 0
                            ? const Text(
                                "Do you want to mark this task as complete?")
                            : const Text(
                                "Do you want to mark this task as Incomplete?"),
                        actions: [
                          TextButton(
                            child: const Text("No, Thanks!"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child: const Text("Yes, Please!"),
                            onPressed: () async {
                              if (widget.task.isCompleted == 0) {
                                taskController
                                    .markAsComplete(widget.task.task_id);
                                if (widget.task.notification_id != null &&
                                    widget.task.need_notify == 1) {
                                  await AwesomeNotifications().cancelSchedule(
                                      widget.task.notification_id as int);
                                }
                              } else {
                                taskController
                                    .markAsIncomplete(widget.task.task_id);
                                if (widget.task.notification_id != null &&
                                    widget.task.need_notify == 1) {
                                  //need notify ki doent need notify
                                  await createTaskReminderNotification(
                                      DateFormat("EEEE, MMMM d,yyyy h:mm a")
                                          .parse(widget.task.date +
                                              " " +
                                              widget.task.time),
                                      widget.task,
                                      widget.task.notification_id);
                                }
                              }

                              taskController
                                  .getTasksOfCategory(widget.task.category);
                              Navigator.pop(context);
                            },
                          )
                        ],
                      );
                    });
              }),
          // SlidableAction(
          //     icon: Icons.edit_outlined,
          //     backgroundColor: const Color(0xff5388b4),
          //     onPressed: (context) {}),
          SlidableAction(
              icon: Icons.delete_outline,
              backgroundColor: Colors.red,
              onPressed: (context) async {
                showDialog(
                    context: context,
                    builder: (BuildContext alert_context) {
                      return AlertDialog(
                        title: const Text("Are you sure?"),
                        content: const Text(
                            "Do you want to remove this task from the list?"),
                        actions: [
                          TextButton(
                            child: const Text("No, Thanks!"),
                            onPressed: () {
                              Navigator.pop(alert_context);
                            },
                          ),
                          TextButton(
                            child: const Text("Yes, Please!"),
                            onPressed: () {
                              if (widget.task.notification_id != null) {
                                AwesomeNotifications().cancelSchedule(
                                    widget.task.notification_id as int);
                              }
                              taskController.removeTask(widget.task.task_id);
                              categoryController.getTasksCount();
                              Navigator.pop(alert_context);
                            },
                          )
                        ],
                      );
                    });
              }),
        ],
      ),
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 5, 0),
          padding: const EdgeInsets.fromLTRB(5, 13, 5, 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(
                Icons.check_circle,
                color: widget.task.isCompleted == 1
                    ? Colors.green
                    : Colors.white10,
              ),
              Text(
                widget.task.time,
              ),
              SizedBox(
                width: 180,
                child: Text(
                  widget.task.title,
                ),
              ),
              /*const Icon(Icons.notifications),*/
            ],
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: const [0.015, 0.015],
              colors: [Color(widget.cardColor), secondaryColor],
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
        ),
        onTap: () async {
          showModalBottomSheet(
              context: context,
              builder: (context) {
                return FutureBuilder(
                  future: getCategory(widget.task.category + 1),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    Category category;
                    LineSplitter lineSplitter = const LineSplitter();
                    List<String> subTaskList =
                        lineSplitter.convert(widget.task.subTasks);
                    if (snapshot.hasData) {
                      category = Category.fromMap(
                          jsonDecode(jsonEncode(snapshot.data)));
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        child: Icon(
                                          deserializeIcon(category.category_icon
                                              as Map<String, dynamic>),
                                          color: Color(category.category_color),
                                          size: 50,
                                        ),
                                        decoration: const BoxDecoration(
                                          color:
                                              Color.fromRGBO(10, 10, 10, 100),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30.0),
                                          ),
                                        ),
                                      ),
                                      flex: 2,
                                    ),
                                    const Expanded(
                                      child: VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 2,
                                        indent: 25,
                                        endIndent: 25,
                                      ),
                                      flex: 1,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.task.title
                                                  .toString()
                                                  .toUpperCase(),
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                            Text(widget.task.date.toString()),
                                            Text(widget.task.time.toString()),
                                            Chip(
                                              label: Text(widget
                                                  .task.category_name
                                                  .toString()),
                                              backgroundColor:
                                                  Color(widget.cardColor),
                                            )
                                          ],
                                        ),
                                      ),
                                      flex: 4,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: const [
                                      Text(
                                        "Description : ",
                                        style: TextStyle(fontSize: 18),
                                      )
                                    ]),
                                    widget.task.description.toString().isEmpty
                                        ? const Center(
                                            child: BulletedList(
                                            listItems: [
                                              Text('No Description!')
                                            ],
                                            bullet: Icon(
                                                Icons.warning_amber_outlined),
                                          ))
                                        : BulletedList(
                                            listItems: [
                                              Text(widget.task.description,
                                                  textAlign: TextAlign.justify)
                                            ],
                                            bullet:
                                                const Icon(Icons.note_outlined),
                                          ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    Row(children: const [
                                      Text(
                                        "Sub-Tasks : ",
                                        style: TextStyle(fontSize: 18),
                                      )
                                    ]),
                                    subTaskList.isEmpty
                                        ? const Center(
                                            child: BulletedList(
                                            listItems: [Text('No Sub-tasks!')],
                                            bullet: Icon(
                                                Icons.warning_amber_outlined),
                                          ))
                                        : BulletedList(
                                            listItems: subTaskList,
                                            bullet: const Icon(Icons.task),
                                          ),
                                  ],
                                )),
                          ],
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                );
              });
        },
      ),
    );
  }

  getCategory(int id) async {
    final category = await DatabaseHelper.instance.getCategoryOfTask(id);
    return category;
  }
}
