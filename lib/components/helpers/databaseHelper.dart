import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/IconPicker/iconPicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../models/Category.dart';
import '../models/Task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _db;

  DatabaseHelper._instance();

  String toDoListTable = 'to_do_list_table';
  String categoryTable = 'category_table';
  String colTaskId = 'task_id';
  String colCategoryId = 'category_id';
  String colCategoryName = 'category_name';
  String colDate = 'date';
  String colTime = 'time';
  String colDeadline = 'deadline';
  String colTitle = 'title';
  String colDescription = 'description';
  String colSubTasks = 'subTasks';
  String colCategory = 'category';
  String colIcon = 'category_icon';
  String colColor = 'category_color';
  String colIsCompleted = 'isCompleted';
  String colNotificationId = 'notification_id';
  String colNeedNotify = 'need_notify';

  Future<Database> get db async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = dir.path + 'to_do_list.db';
    final toDoListDb =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return toDoListDb;
  }

  void _createDb(Database db, int version) async {
    final icon1 = serializeIcon(Icons.timer);
    var color1 = Colors.red.value;
    var icon2 = serializeIcon(Icons.tag);
    var color2 = Colors.yellow.value;
    var icon3 = serializeIcon(Icons.business);
    var color3 = Colors.deepPurple.value;
    await db.execute(
        'CREATE TABLE $toDoListTable($colTaskId INTEGER PRIMARY KEY AUTOINCREMENT,$colTitle TEXT,$colDescription TEXT,$colSubTasks TEXT,$colCategory INTEGER,$colCategoryName TEXT,$colDeadline TEXT, $colDate DATETIME, $colTime TEXT, $colIsCompleted int, $colNotificationId int, $colNeedNotify int)');
    await db.execute(
        'CREATE TABLE $categoryTable($colCategoryId INTEGER PRIMARY KEY AUTOINCREMENT,$colCategoryName TEXT,$colColor INTEGER, $colIcon TEXT)');
    await db.insert(
        categoryTable,
        Category(
                category_icon: icon1,
                category_color: color1,
                category_name: 'Important')
            .toMap());
    await db.insert(
        categoryTable,
        Category(
                category_icon: icon2,
                category_color: color2,
                category_name: 'Daily')
            .toMap());
    await db.insert(
        categoryTable,
        Category(
                category_icon: icon3,
                category_color: color3,
                category_name: 'Business')
            .toMap());
  }

  Future<List<Task>> getFreshTasksList() async {
    Database db = await this.db;
    final List<Map<String, dynamic>> tasksMapList =
        await db.query(toDoListTable);
    List<Task> tasksList = [];
    tasksMapList.forEach((tasksListMap) {
      int dateCompare = DateFormat('EEEE, MMMM d,yyyy')
          .parse(tasksListMap['date'].toString())
          .compareTo(DateFormat('EEEE, MMMM d, yyyy')
              .parse(DateFormat.yMMMMEEEEd().format(DateTime.now())));
      if (dateCompare == 1 || dateCompare == 0) {
        tasksList.add(Task.fromMap(tasksListMap));
      }
    });
    return tasksList;
  }

  Future<List<Task>> getPreviousTasksList(int days) async {
    Database db = await this.db;
    final List<Map<String, dynamic>> tasksMapList =
        await db.query(toDoListTable);
    List<Task> tasksList = [];
    tasksMapList.forEach((tasksListMap) {
      bool isAfter = DateFormat('EEEE, MMMM d,yyyy')
          .parse(tasksListMap['date'].toString())
          .isAfter(DateFormat('EEEE, MMMM d, yyyy').parse(
              DateFormat.yMMMMEEEEd().format(DateTime(DateTime.now().year,
                  DateTime.now().month, DateTime.now().day - days))));
      if (isAfter) {
        tasksList.add(Task.fromMap(tasksListMap));
      }
    });
    return tasksList;
  }

  Future<List<Map<String, dynamic>>> getTasksMapList(id) async {
    Database db = await this.db;
    final List<Map<String, dynamic>> result =
        await db.query(toDoListTable, where: '$colTaskId = ?', whereArgs: [id]);
    return result;
  }

  Future<List<Task>> getTasksList(id) async {
    final List<Map<String, dynamic>> tasksMapList = await getTasksMapList(id);
    final List<Task> tasksList = [];
    tasksMapList.forEach((tasksListMap) {
      tasksList.add(Task.fromMap(tasksListMap));
    });
    return tasksList;
  }

  Future<List<Task>> getTasksOfCategory(id) async {
    Database db = await this.db;
    final List<Map<String, dynamic>> tasksMapList = await db
        .query(toDoListTable, where: "$colCategory = ?", whereArgs: [id]);
    List<Task> tasksList = [];
    tasksMapList.forEach((tasksListMap) {
      tasksList.add(Task.fromMap(tasksListMap));
    });
    return tasksList;
  }

  Future<List<Category>> getAllCategoryList() async {
    Database db = await this.db;
    final List<Map<String, dynamic>> categoryMapList =
        await db.query(categoryTable);
    List<Category> categoryList = [];
    categoryMapList.forEach((categoriesListMap) {
      categoryList.add(Category.fromMap(categoriesListMap));
    });
    return categoryList;
  }

  Future<List<Map<String, dynamic>>> getCategoryMapList(id) async {
    Database db = await this.db;
    final List<Map<String, dynamic>> result = await db
        .query(categoryTable, where: '$colCategoryId = ?', whereArgs: [id]);
    return result;
  }

  Future<List<Category>> getCategoryList(id) async {
    final List<Map<String, dynamic>> categoryMapList =
        await getCategoryMapList(id);
    final List<Category> categoryList = [];
    categoryMapList.forEach((categoryListMap) {
      categoryList.add(Category.fromMap(categoryListMap));
    });
    return categoryList;
  }

  Future<List<Map<String, Object?>>> getCategory(id) async {
    Database db = await this.db;
    final category = await db
        .query(categoryTable, where: '$colCategoryId=?', whereArgs: [id]);
    return category;
  }

  Future<int> insertTask(Task task) async {
    Database db = await this.db;
    final int result = await db.insert(toDoListTable, task.toMap());
    return result;
  }

  Future<int> updateTask(Task task) async {
    Database db = await this.db;
    final int result = await db.update(toDoListTable, task.toMap(),
        where: '$colTaskId = ?', whereArgs: [task.task_id]);
    return result;
  }

  Future<int> deleteTask(int id) async {
    Database db = await this.db;
    final int result = await db.delete(
      toDoListTable,
      where: '$colTaskId = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> insertCategory(Category category) async {
    Database db = await this.db;
    final int result = await db.insert(categoryTable, category.toMap());
    return result;
  }

  Future<int> updateCategory(Category category) async {
    Database db = await this.db;
    final int result = await db.update(toDoListTable, category.toMap(),
        where: '$colCategoryId = ?', whereArgs: [category.category_id]);
    return result;
  }

  Future<int> deleteCategory(int id) async {
    Database db = await this.db;
    final int result = await db.delete(
      toDoListTable,
      where: '$colCategoryId = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<Map<String, Object?>> getCategoryOfTask(int id) async {
    Database db = await this.db;
    final category = await db
        .query(categoryTable, where: "$colCategoryId = ?", whereArgs: [id]);
    return category[0];
  }

  Future<List<Map<String, Object?>>> getCategoryColor(int id) async {
    Database db = await this.db;
    final color = await db.query(categoryTable,
        columns: [colColor], where: "$colCategoryId = ?", whereArgs: [id]);
    return color;
  }

  Future<Map<String, Object?>> getCategoryIcon(int id) async {
    Database db = await this.db;
    final icon = await db.query(categoryTable,
        columns: [colIcon], where: "$colCategoryId = ?", whereArgs: [id]);
    return icon[0];
  }

  Future<Map<String, int>> getTasksOnCategoryCount() async {
    Map<String, int> map = {};
    Database db = await this.db;
    final result = await db.rawQuery(
        "SELECT $colCategory AS id,COUNT($colTaskId) AS count FROM $toDoListTable GROUP BY  $colCategory");
    result.forEach((element) {
      map[Map<String, int>.from(element)['id'].toString()] =
          Map<String, int>.from(element)['count'] as int;
    });
    return map;
  }

  Future<void> markTaskAsCompleted(int id) async {
    Database db = await this.db;
    await db.rawQuery(
        "UPDATE $toDoListTable SET $colIsCompleted = 1 WHERE $colTaskId = $id");
  }

  Future<void> markTaskAsIncompleted(int id) async {
    Database db = await this.db;
    await db.rawQuery(
        "UPDATE $toDoListTable SET $colIsCompleted = 0 WHERE $colTaskId = $id");
  }

  Future<void> toggleNotify(int id) async {
    Database db = await this.db;
    await db.rawQuery(
        "UPDATE $toDoListTable SET $colNeedNotify = !$colNeedNotify WHERE $colTaskId = $id");
  }
}
