import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:grouped_list/grouped_list.dart';
import '../../constants.dart';
import '../controllers/CategoryController.dart';
import '../controllers/TaskController.dart';
import '../models/Category.dart';
import '../models/Task.dart';
import 'TaskCard.dart';

class CardwIcon extends StatefulWidget {
  final category;
  final theContext;
  const CardwIcon({Key? key, required this.category, this.theContext})
      : super(key: key);

  @override
  _CardwIconState createState() => _CardwIconState();
}

class _CardwIconState extends State<CardwIcon> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Provider.of<TaskController>(context, listen: true);
    final categoryController =
        Provider.of<CategoryController>(context, listen: true);
    return InkWell(
      child: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Container(
                    width: 70,
                    height: 70,
                    child: Icon(
                      deserializeIcon(widget.category.category_icon),
                      color: Color(widget.category.category_color),
                      size: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Color(widget.category.category_color)
                          .withOpacity(0.1),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(50.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.category.category_name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                    context
                                .read<CategoryController>()
                                .categoryTaskNumMap[
                                    (widget.category.category_id - 1)
                                        .toString()]
                                .toString() !=
                            "null"
                        ? context
                                .read<CategoryController>()
                                .categoryTaskNumMap[
                                    (widget.category.category_id - 1)
                                        .toString()]
                                .toString() +
                            ' Tasks'
                        : 'No Tasks',
                    style: const TextStyle(
                      fontSize: 8,
                    )),
              ],
            ),
          ),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
            color: secondaryColor,
          ),
          margin: const EdgeInsets.all(10),
          height: 150.0),
      onTap: () {
        context
            .read<TaskController>()
            .getTasksOfCategory(widget.category.category_id - 1);
        showModalBottomSheet(
            context: context,
            backgroundColor: bgColor,
            constraints: BoxConstraints.loose(Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height * 0.75)),
            isScrollControlled: true,
            builder: (modalContext) {
              return MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: taskController),
                    ChangeNotifierProvider.value(value: categoryController)
                  ],
                  builder: (modalContext, child) {
                    return StatefulBuilder(builder: (modalContext, state) {
                      List<Task> tasks = modalContext
                          .watch<TaskController>()
                          .taskListOfCategory;
                      if (tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.task_outlined,
                                size: 50,
                              ),
                              Text("No Tasks!"),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GroupedListView<dynamic, String>(
                          padding: const EdgeInsets.only(bottom: 25),
                          elements: tasks,
                          groupBy: (task) => task.date,
                          groupSeparatorBuilder: (String groupByValue) =>
                              Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(groupByValue),
                          ),
                          itemBuilder: (context, dynamic task) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TaskCard(
                                task: task,
                                cardColor: widget.category.category_color),
                          ),
                          itemComparator: (item1, item2) => DateFormat("h:mm a")
                              .parse(item1.time)
                              .compareTo(
                                  DateFormat("h:mm a").parse(item2.time)),
                          groupComparator: (item1, item2) => DateFormat(
                                  "EEEE, MMMM d,yyyy")
                              .parse(item1)
                              .compareTo(
                                  DateFormat("EEEE, MMMM d,yyyy").parse(item2)),
                          // optional
                          floatingHeader: true,
                          order: GroupedListOrder.ASC,
                        ),
                      );
                    });
                  });
            });
      },
    );
  }
}
