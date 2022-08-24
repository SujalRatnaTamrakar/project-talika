import 'dart:convert';

class Category {
  String category_name;
  Map<String, dynamic>? category_icon;
  int? category_id;
  int category_color;

  Category(
      {required this.category_name,
      required this.category_icon,
      required this.category_color});

  Category.withId(
      {required this.category_name,
      required this.category_icon,
      required this.category_color,
      this.category_id});

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['category_name'] = category_name;
    map['category_icon'] = jsonEncode(category_icon);
    map['category_color'] = category_color;
    if (category_id != null) {
      map['category_id'] = category_id;
    }

    return map;
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category.withId(
        category_id: map['category_id'],
        category_name: map['category_name'],
        category_icon: jsonDecode(map['category_icon']),
        category_color: map['category_color']);
  }
}
