import 'package:flutter/material.dart';

import '../helpers/databaseHelper.dart';
import '../models/Category.dart';
import '../widgets/CardwIcon.dart';

class CategoryController extends ChangeNotifier {
  List<Category> _categoryList = [];
  List<String> _categoryNameList = [];
  Map<String, int> _categoryMap = {};
  List<Widget> _categoryCards = [];
  Map<String, int> _categoryTaskNumMap = {};
  Color _selectedColor = const Color(0xFF56B633);
  Icon? _icon;
  IconData _iconData = Icons.task;
  final _categoryFormKey = GlobalKey<FormState>();
  int _tag = 0;

  List<Category> get categoryList => _categoryList;

  List<String> get categoryNameList => _categoryNameList;

  Map<String, int> get categoryMap => _categoryMap;

  List<Widget> get categoryCards => _categoryCards;

  get categoryFormKey => _categoryFormKey;

  Map<String, int> get categoryTaskNumMap => _categoryTaskNumMap;

  Color get selectedColor => _selectedColor;

  Icon? get icon => _icon;

  IconData get iconData => _iconData;

  int get tag => _tag;

  CategoryController() {
    getAllCategories();
    getCategoryCards();
    getTasksCount();
    notifyListeners();
  }

  getCategoryCards() {
    _categoryList.forEach((category) {
      _categoryCards.add(CardwIcon(category: category));
    });
    notifyListeners();
  }

  getAllCategories() async {
    var categoriesList = await DatabaseHelper.instance.getAllCategoryList();
    for (var category in categoriesList) {
      _categoryList.add(category);
      _categoryNameList.add(category.category_name);
      _categoryMap[category.category_name] = category.category_color;
    }
    getCategoryCards();
    notifyListeners();
  }

  insertCategory(Category category) async {
    final result = await DatabaseHelper.instance.insertCategory(category);
    if (result.isFinite) {
      category.category_id = result;
      _categoryCards.add(CardwIcon(category: category));
      _categoryMap[category.category_name] = category.category_color;
    }
    notifyListeners();
  }

  getTasksCount() async {
    final result = await DatabaseHelper.instance.getTasksOnCategoryCount();
    _categoryTaskNumMap = result;
    notifyListeners();
  }

  setSelectedColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  setIcon(Icon? icon) {
    _icon = icon;
    notifyListeners();
  }

  setIconData(IconData iconData) {
    _iconData = iconData;
    notifyListeners();
  }

  setTag(int tag) {
    _tag = tag;
    notifyListeners();
  }

  clearCategories() {
    _categoryList.clear();
    _categoryNameList.clear();
    _categoryMap.clear();
    _categoryCards.clear();
    notifyListeners();
  }
}
