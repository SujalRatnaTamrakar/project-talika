import 'package:flutter/material.dart';

class NavigationController extends ChangeNotifier {
  int _selectedTab = 0;

  int get selectedTab => _selectedTab;

  updateSelectedTab(int selectedTab) {
    _selectedTab = selectedTab;
    notifyListeners();
  }
}
