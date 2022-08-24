import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chips_choice_null_safety/chips_choice_null_safety.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:grouped_list/grouped_list_with_refresh.dart';

import 'components/controllers/CategoryController.dart';
import 'components/controllers/NavigationController.dart';
import 'components/controllers/TaskController.dart';
import 'components/helpers/notificationsHelper.dart';
import 'components/models/Category.dart';
import 'components/models/Task.dart';
import 'components/widgets/CardwIcon.dart';
import 'components/widgets/TaskCard.dart';
import 'constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ToDoListScreen extends StatefulWidget {
  static const id = 'ToDoListScreen';
  const ToDoListScreen({Key? key}) : super(key: key);

  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  late BannerAd _bannerAd;
  late NativeAd _nativeAd;
  bool _isAdLoaded = false;
  bool _isNativeAdLoaded = false;

  @override
  void dispose() {
    super.dispose();
    _bannerAd.dispose();
    _nativeAd.dispose();
  }

  @override
  void initState() {
    super.initState();
    requestBasicPermission();
    requestPermissions();
    // _initBannerAd();
    // _initNativeAd();
  }

  requestBasicPermission() async {
    await requestBasicPermissionToSendNotifications(context);
  }

  requestPermissions() async {
    await requestUserPermissions(context,
        channelKey: 'task_reminder_channel',
        permissionList: [NotificationPermission.Alert]);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
  }

  _initBannerAd() {
    _bannerAd = BannerAd(
      request: const AdRequest(),
      adUnitId: 'ad-unit-id',
      size: AdSize.banner,
      listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {}),
    );

    _bannerAd.load();
  }

  _initNativeAd() {
    _nativeAd = NativeAd(
      request: const AdRequest(),
      adUnitId: 'ad-unit-id',
      listener: NativeAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isNativeAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {}),
      factoryId: 'listTile',
    );

    _nativeAd.load();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _taskTitleController = TextEditingController();
    TextEditingController _taskDateTimeController = TextEditingController();
    TextEditingController _taskDescController = TextEditingController();
    TextEditingController _categoryNameController = TextEditingController();
    RefreshController _refreshController =
        RefreshController(initialRefresh: false);
    bool _needNotify = false;
    Map<String, NativeAd> ads = <String, NativeAd>{};
    Map<String, BannerAd> bannerAds = <String, BannerAd>{};

    void _onRefresh() async {
      // monitor network fetch
      await context.read<TaskController>().increaseReloadCalled();
      await context.read<TaskController>().getLastMonthTasks();
      // if failed,use refreshFailed()
      if (mounted) setState(() {});
      _refreshController.refreshCompleted();
    }

    void _onLoading() async {
      print("loading");
      // monitor network fetch
      // if failed,use loadFailed(),if no data return,use LoadNodata()
      // if (mounted) setState(() {});
      _refreshController.loadComplete();
    }

    List<Widget> _widgetOptions = <Widget>[
      context.watch<TaskController>().taskList.isEmpty
          ? Center(
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
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GroupedListView<dynamic, String>(
                onLoading: _onLoading,
                onRefresh: _onRefresh,
                refreshController: _refreshController,
                header: const ClassicHeader(
                  releaseText: "Release to load previous tasks",
                  refreshingText: "Loading",
                  completeText: "Completed",
                  idleText: "Load tasks from 5 days",
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 25),
                elements: context.watch<TaskController>().taskList,
                groupBy: (task) => task.date,
                groupSeparatorBuilder: (String groupByValue) {
                  bannerAds[groupByValue] = BannerAd(
                      adUnitId: 'ad-unit-id',
                      request: AdRequest(),
                      listener:
                          BannerAdListener(onAdClosed: (ad) => ad.dispose()),
                      size: AdSize.banner);
                  bannerAds[groupByValue]?.load();
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        (bannerAds[groupByValue] == null)
                            ? Container()
                            : Container(
                                height: 50,
                                child: AdWidget(
                                  ad: bannerAds[groupByValue] as BannerAd,
                                ),
                              ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(groupByValue),
                      ],
                    ),
                  );
                },
                itemBuilder: (context, dynamic task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TaskCard(
                    task: task,
                    cardColor:
                        Provider.of<CategoryController>(context, listen: false)
                                    .categoryMap[task.category_name] !=
                                null
                            ? Provider.of<CategoryController>(context,
                                    listen: false)
                                .categoryMap[task.category_name] as int
                            : secondaryColor.value,
                  ),
                ),
                itemComparator: (item1, item2) => DateFormat("h:mm a")
                    .parse(item1.time)
                    .compareTo(DateFormat("h:mm a").parse(item2.time)),
                groupComparator: (item1, item2) =>
                    DateFormat("EEEE, MMMM d,yyyy").parse(item1).compareTo(
                        DateFormat("EEEE, MMMM d,yyyy")
                            .parse(item2)), // optional
                floatingHeader: true,
                order: GroupedListOrder.ASC,
              ),
            ),
      Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) => Container(
                            margin: const EdgeInsets.only(
                                left: 10, top: 15, bottom: 0),
                            child: const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      childCount: 1),
                ),
                SliverGrid.count(
                  crossAxisCount: 3,
                  children:
                      Provider.of<CategoryController>(context).categoryCards,
                ),
              ],
            ),
          )),
    ];

    _pickIcon(BuildContext statefulContext) async {
      IconData? icon = await FlutterIconPicker.showIconPicker(statefulContext,
          adaptiveDialog: true,
          iconPackModes: [
            IconPack.material,
          ]);
      statefulContext
          .read<CategoryController>()
          .setIconData(icon ?? Icons.error);
      statefulContext.read<CategoryController>().setIcon(Icon(
            icon ?? Icons.task,
            size: 60,
          ));
    }

    getAddCategoryModal(BuildContext ctx) {
      return showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          constraints: BoxConstraints.loose(Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.7)),
          builder: (statefulContext) {
            return StatefulBuilder(builder: (statefulContext, state) {
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => TaskController()),
                  ChangeNotifierProvider(create: (_) => CategoryController()),
                ],
                builder: (statefulContext, child) => Form(
                  key: context.read<CategoryController>().categoryFormKey,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                                top: 15, left: 20, bottom: 15),
                            child: const Text(
                              'Add a new category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  controller: _categoryNameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    if (value.length > 15) {
                                      return 'The category name should be less than 15 characters!';
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Category Name',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Select an Icon : ",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 90,
                                          height: 90,
                                          child: Card(
                                            color: Colors.grey[900],
                                            shape: RoundedRectangleBorder(
                                              side: const BorderSide(
                                                  color: Colors.white70,
                                                  width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              icon: statefulContext
                                                      .watch<
                                                          CategoryController>()
                                                      .icon ??
                                                  const Icon(
                                                    Icons.add,
                                                    size: 60,
                                                  ),
                                              onPressed: () {
                                                _pickIcon(statefulContext);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Pick a color : ",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Card(
                                          color: Colors.grey[900],
                                          shape: RoundedRectangleBorder(
                                            side: const BorderSide(
                                                color: Colors.white70,
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: ColorIndicator(
                                              width: 80,
                                              height: 80,
                                              borderRadius: 10,
                                              color: statefulContext
                                                  .watch<CategoryController>()
                                                  .selectedColor,
                                              elevation: 1,
                                              onSelectFocus: false,
                                              onSelect: () async {
                                                // Wait for the dialog to return color selection result.
                                                final Color newColor =
                                                    await showColorPickerDialog(
                                                  // The dialog needs a context, we pass it in.
                                                  statefulContext,
                                                  // We use the dialogSelectColor, as its starting color.
                                                  statefulContext
                                                      .read<
                                                          CategoryController>()
                                                      .selectedColor,
                                                  title: Text('ColorPicker',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline6),
                                                  width: 40,
                                                  height: 40,
                                                  spacing: 0,
                                                  runSpacing: 0,
                                                  borderRadius: 0,
                                                  wheelDiameter: 165,
                                                  enableOpacity: false,
                                                  showColorCode: false,
                                                  colorCodeHasColor: true,
                                                  pickersEnabled: <
                                                      ColorPickerType, bool>{
                                                    ColorPickerType.both: true,
                                                    ColorPickerType.primary:
                                                        false,
                                                    ColorPickerType.accent:
                                                        false,
                                                  },
                                                  copyPasteBehavior:
                                                      const ColorPickerCopyPasteBehavior(
                                                    copyButton: false,
                                                    pasteButton: false,
                                                    longPressMenu: false,
                                                  ),
                                                  actionButtons:
                                                      const ColorPickerActionButtons(
                                                    okButton: true,
                                                    closeButton: true,
                                                    dialogActionButtons: false,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minHeight: 320,
                                                          minWidth: 320,
                                                          maxWidth: 320),
                                                );
                                                // We update the dialogSelectColor, to the returned result
                                                // color. If the dialog was dismissed it actually returns
                                                // the color we started with. The extra update for that
                                                // below does not really matter, but if you want you can
                                                // check if they are equal and skip the update below.

                                                statefulContext
                                                    .read<CategoryController>()
                                                    .setSelectedColor(newColor);
                                              }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.tealAccent.shade200),
                                      onPressed: () async {
                                        if (context
                                            .read<CategoryController>()
                                            .categoryFormKey
                                            .currentState!
                                            .validate()) {
                                          Category category = Category(
                                              category_name:
                                                  _categoryNameController
                                                      .value.text,
                                              category_icon: serializeIcon(
                                                  statefulContext
                                                      .read<
                                                          CategoryController>()
                                                      .iconData),
                                              category_color: statefulContext
                                                  .read<CategoryController>()
                                                  .selectedColor
                                                  .value);
                                          ctx
                                              .read<CategoryController>()
                                              .insertCategory(category);
                                          ctx
                                              .read<CategoryController>()
                                              .getTasksCount();
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text(
                                        "Add Category",
                                        style: TextStyle(color: Colors.black),
                                      )),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(
                            height: 50,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          });
    }

    getAddTaskModal(BuildContext ctx) {
      return showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        constraints: BoxConstraints.loose(Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height * 0.7)),
        builder: (statefulContext) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => TaskController()),
              ChangeNotifierProvider(create: (_) => CategoryController()),
            ],
            builder: (statefulContext, child) =>
                StatefulBuilder(builder: (context, state) {
              return Form(
                key: context.read<TaskController>().taskFormKey,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              top: 15, left: 20, bottom: 15),
                          child: const Text(
                            'Add a new task',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              TextFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                controller: _taskTitleController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the title!';
                                  }
                                  if (value.length > 15) {
                                    return 'The title should be less than 15 characters!';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Title',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            color: secondaryColor,
                            margin: const EdgeInsets.all(5),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom:
                                              BorderSide(color: Colors.grey))),
                                  child: const Text(
                                    "Category",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: ChipsChoice<int>.single(
                                    value: statefulContext
                                        .read<CategoryController>()
                                        .tag,
                                    onChanged: (val) => statefulContext
                                        .read<CategoryController>()
                                        .setTag(val),
                                    choiceItems: C2Choice.listFrom<int, String>(
                                      source: statefulContext
                                          .watch<CategoryController>()
                                          .categoryNameList,
                                      value: (i, v) => i,
                                      label: (i, v) => v,
                                      style: (i, v) {
                                        return C2ChoiceStyle(
                                          color: Color(statefulContext
                                                  .read<CategoryController>()
                                                  .categoryMap[v] as int)
                                              .withOpacity(0.3),
                                        );
                                      },
                                      activeStyle: (i, v) {
                                        return C2ChoiceStyle(
                                          color: Color(statefulContext
                                              .read<CategoryController>()
                                              .categoryMap[v] as int),
                                        );
                                      },
                                    ),
                                    choiceStyle: const C2ChoiceStyle(
                                      color: Colors.green,
                                      brightness: Brightness.dark,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: DateTimeField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: _taskDateTimeController,
                            validator: (value) {
                              if (value == null) {
                                return 'Please select the date !';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                                label: Text("Target Date & Time"),
                                border: OutlineInputBorder()),
                            format:
                                DateFormat("EEEE, MMMM d, yyyy 'at' h:mm a"),
                            onShowPicker: (context, currentValue) async {
                              final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                initialDate: currentValue ?? DateTime.now(),
                                lastDate: DateTime(DateTime.now().year + 1),
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                      currentValue ?? DateTime.now()),
                                );
                                return DateTimeField.combine(date, time);
                              } else {
                                return currentValue;
                              }
                            },
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Card(
                              color: secondaryColor,
                              shadowColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: SwitchListTile(
                                onChanged: (bool value) {
                                  state(() {
                                    _needNotify = value;
                                  });
                                },
                                value: _needNotify,
                                title: const Text(
                                  "Notify before an hour?",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextFormField(
                            controller: _taskDescController,
                            minLines: 6,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(
                                label: Text("Description"),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder()),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              children: statefulContext
                                  .watch<TaskController>()
                                  .subTaskFields,
                            ),
                            ListTile(
                              title: Row(
                                children: const [
                                  Icon(Icons.add),
                                  Text("Add a Sub-task")
                                ],
                              ),
                              onTap: () {
                                Provider.of<TaskController>(statefulContext,
                                        listen: false)
                                    .addTextField();
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.tealAccent.shade200),
                                      onPressed: () async {
                                        if (context
                                            .read<TaskController>()
                                            .taskFormKey
                                            .currentState!
                                            .validate()) {
                                          String text =
                                              Provider.of<TaskController>(
                                                      context,
                                                      listen: false)
                                                  .controllers
                                                  .where(
                                                      (element) =>
                                                          element.text != "")
                                                  .fold(
                                                      "",
                                                      (acc, element) => acc +=
                                                          "${element.text}\n");
                                          int notificationId = createUniqueId();
                                          Task task = Task(
                                              title: _taskTitleController.text
                                                  .trim(),
                                              description: _taskDescController
                                                  .text
                                                  .trim(),
                                              subTasks: text.trim(),
                                              date: DateFormat("EEEE, MMMM d,yyyy")
                                                  .format(DateFormat(
                                                          "EEEE, MMMM d, yyyy 'at' h:mm a")
                                                      .parse(
                                                          _taskDateTimeController
                                                              .text)
                                                      .toLocal()),
                                              time: DateFormat("h:mm a").format(
                                                  DateFormat("EEEE, MMMM d, yyyy 'at' h:mm a")
                                                      .parse(
                                                          _taskDateTimeController.text)
                                                      .toLocal()),
                                              category: Provider.of<CategoryController>(context, listen: false).tag,
                                              category_name: Provider.of<CategoryController>(context, listen: false).categoryNameList[Provider.of<CategoryController>(context, listen: false).tag],
                                              isCompleted: 0,
                                              notification_id: _needNotify ? notificationId : null,
                                              need_notify: _needNotify ? 1 : 0);
                                          ctx
                                              .read<TaskController>()
                                              .insertTask(task);
                                          ctx
                                              .read<CategoryController>()
                                              .getTasksCount();
                                          if (_needNotify) {
                                            createTaskReminderNotification(
                                                DateFormat(
                                                        "EEEE, MMMM d, yyyy 'at' h:mm a")
                                                    .parse(
                                                        _taskDateTimeController
                                                            .text),
                                                task,
                                                notificationId);
                                          }
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text(
                                        "Add Task",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 50,
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _widgetOptions
                  .elementAt(context.watch<NavigationController>().selectedTab),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: context.read<NavigationController>().selectedTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          BottomNavigationBarItem(
              icon: Icon(Icons.category), label: "Categories")
        ],
        onTap: (index) =>
            {context.read<NavigationController>().updateSelectedTab(index)},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          context.read<NavigationController>().selectedTab == 0
              ? getAddTaskModal(context)
              : getAddCategoryModal(context);
        },
      ),
    );
  }
}
