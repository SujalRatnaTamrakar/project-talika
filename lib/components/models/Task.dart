class Task {
  String title, description, date, time, category_name, subTasks;
  int category, isCompleted;
  int? task_id;
  int? notification_id;
  int? need_notify;

  Task(
      {required this.title,
      required this.description,
      required this.subTasks,
      required this.date,
      required this.time,
      required this.category,
      required this.category_name,
      required this.isCompleted,
      this.notification_id,
      this.need_notify});

  Task.withId(
      {required this.title,
      required this.description,
      required this.subTasks,
      required this.date,
      required this.time,
      required this.category,
      required this.category_name,
      required this.isCompleted,
      this.notification_id,
      this.task_id,
      this.need_notify});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['description'] = description;
    map['subTasks'] = subTasks;
    map['date'] = date;
    map['time'] = time;
    map['category'] = category;
    map['category_name'] = category_name;
    map['isCompleted'] = isCompleted;
    if (task_id != null) {
      map['task_id'] = task_id;
    }
    if (notification_id != null) {
      map['notification_id'] = notification_id;
    }
    if (need_notify != null) {
      map['need_notify'] = need_notify;
    }

    return map;
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task.withId(
        task_id: map['task_id'],
        title: map['title'],
        description: map['description'],
        subTasks: map['subTasks'],
        date: map['date'],
        time: map['time'],
        category: map['category'],
        category_name: map['category_name'],
        notification_id: map['notification_id'],
        need_notify: map['need_notify'],
        isCompleted: map['isCompleted']);
  }
}
