import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import '../helpers/databaseHelper.dart';
import '../models/Task.dart';

class TaskController extends ChangeNotifier {
  List<Task> _taskList = [];
  List<Task> _taskListOfCategory = [];
  List<TextEditingController> _controllers = [];
  List<Padding> _subTaskFields = [];
  final _taskFormKey = GlobalKey<FormState>();
  int _reloadCalled = 0;

  TaskController() {
    getAllTask();
  }

  List<Task> get taskList => _taskList;

  List<TextEditingController> get controllers => _controllers;

  List<Padding> get subTaskFields => _subTaskFields;

  get taskFormKey => _taskFormKey;

  List<Task> get taskListOfCategory => _taskListOfCategory;

  int get reloadCalled => _reloadCalled;

  getAllTask() async {
    var tasksList = await DatabaseHelper.instance.getFreshTasksList();

    for (var task in tasksList) {
      _taskList.add(task);
    }
    notifyListeners();
  }

  getLastMonthTasks() async {
    var tasksList =
        await DatabaseHelper.instance.getPreviousTasksList(_reloadCalled);
    List<Task> tempList = [];
    for (var task in tasksList) {
      tempList.add(task);
    }
    _taskList = tempList;
    notifyListeners();
  }

  getTasksOfCategory(category_id) async {
    _taskListOfCategory.clear();
    var tasks = await DatabaseHelper.instance.getTasksOfCategory(category_id);
    for (var task in tasks) {
      _taskListOfCategory.add(task);
    }
    notifyListeners();
  }

  insertTask(Task task) async {
    final result = await DatabaseHelper.instance.insertTask(task);
    if (result.isFinite) {
      task.task_id = result;
      _taskList.add(task);
      notifyListeners();
    }
  }

  markAsComplete(int id) async {
    await DatabaseHelper.instance.markTaskAsCompleted(id);
    taskList[taskList.indexWhere((task) => task.task_id == id)].isCompleted = 1;
    if (taskListOfCategory.isNotEmpty) {
      taskListOfCategory[
              taskListOfCategory.indexWhere((task) => task.task_id == id)]
          .isCompleted = 1;
    }
    notifyListeners();
  }

  markAsIncomplete(int id) async {
    await DatabaseHelper.instance.markTaskAsIncompleted(id);
    taskList[taskList.indexWhere((task) => task.task_id == id)].isCompleted = 0;
    if (taskListOfCategory.isNotEmpty) {
      taskListOfCategory[
              taskListOfCategory.indexWhere((task) => task.task_id == id)]
          .isCompleted = 0;
    }
    notifyListeners();
  }

  removeTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    taskList.removeAt(taskList.indexWhere((task) => task.task_id == id));
    // if (taskListOfCategory.isNotEmpty) {
    //   taskListOfCategory.removeAt(
    //       taskListOfCategory.indexWhere((task) => task.task_id == id));
    // }
    notifyListeners();
  }

  clearTasks() {
    _taskList.clear();
    notifyListeners();
  }

  addTextField() {
    final controller = TextEditingController();
    final field = Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Sub-task ${_controllers.length + 1}",
        ),
      ),
    );
    _controllers.add(controller);
    _subTaskFields.add(field);
    notifyListeners();
  }

  increaseReloadCalled() {
    _reloadCalled += 5;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
