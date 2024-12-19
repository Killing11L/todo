import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tray_manager/tray_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WindowOptions windowOptions = const WindowOptions(
    size: Size(330, 350),
    minimumSize: Size(330, 350),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await trayManager.setIcon('assets/icon/todo_icon.ico');

  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'cancel',
        label: '取消',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: '退出',
      ),
    ],
  );
  await trayManager.setToolTip("todo list");
  await trayManager.setContextMenu(menu);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isEnter = ValueNotifier<bool>(false);

    return MaterialApp(
      title: 'Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onPanStart: (details) {
            windowManager.startDragging();
          },
          child: MouseRegion(
            onEnter: (event) {
              isEnter.value = true;
            },
            onExit: (event) {
              isEnter.value = false;
            },
            child: MyHomePage(title: 'Flutter Demo Home Page', isEnter: isEnter),
          ),
        ),
      ),
    );
  }
}

enum PageState {
  todo,
  done,
  setting,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.isEnter});
  final String title;
  final ValueNotifier<bool> isEnter;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TrayListener {
  PageState page = PageState.todo;
  ValueNotifier<double> opacity = ValueNotifier<double>(0.35);
  bool alwaysTop_ = false;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == "exit_app") {
      windowManager.close();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: opacity,
      builder: (BuildContext context, value, Widget? child) {
        return Container(
          padding: const EdgeInsets.all(10),
          clipBehavior: Clip.none,
          color: Colors.black.withOpacity(value),
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: widget.isEnter,
                builder: (context, isEnter, child) {
                  return Container(
                    height: 50,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    page = PageState.todo;
                                  });
                                },
                                child: AnimatedScale(
                                  scale: (page == PageState.todo) ? 1 : 0.7,
                                  duration: const Duration(milliseconds: 100),
                                  child: Text(
                                    "ToDo",
                                    style: TextStyle(
                                      fontSize: 35,
                                      decoration: TextDecoration.none,
                                      color: (page == PageState.todo) ? Colors.white : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    page = PageState.done;
                                  });
                                },
                                child: AnimatedScale(
                                  scale: (page == PageState.done) ? 1 : 0.7,
                                  duration: const Duration(milliseconds: 100),
                                  child: Text(
                                    "Done",
                                    style: TextStyle(
                                      fontSize: 35,
                                      decoration: TextDecoration.none,
                                      color: (page == PageState.done) ? Colors.white : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEnter)
                          Positioned(
                            right: -5,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.push_pin_outlined,
                                    color: alwaysTop_ ? Colors.red : Colors.white,
                                  ),
                                  iconSize: 25,
                                  onPressed: () {
                                    alwaysTop_ = !alwaysTop_;
                                    windowManager.setAlwaysOnTop(alwaysTop_);
                                    setState(() {});
                                  },
                                ),
                                AnimatedScale(
                                  scale: (page == PageState.setting) ? 1 : 0.6,
                                  duration: const Duration(milliseconds: 100),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.settings,
                                      color: Colors.white,
                                    ),
                                    iconSize: 40,
                                    onPressed: () {
                                      setState(() {
                                        page = PageState.setting;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: switch (page) {
                  PageState.todo => const TodoList(),
                  PageState.done => const DoneList(),
                  PageState.setting => SettingPage(opacity: opacity),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  TextStyle taskStyle = const TextStyle(
    fontSize: 20,
    color: Colors.white,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w100,
  );

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _tasks = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final double _totalTasksHeight = 0;
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    List<Map<String, dynamic>> tasks = await _dbHelper.getItems().then((task) {
      return task.where((val) => val['isDone'] == 0).toList();
    });
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _addNewTask() async {
    final id = await _dbHelper.insertItem("", 0);
    _tasks = await _dbHelper.getItems().then((task) {
      return task.where((val) => val['isDone'] == 0).toList();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[id]?.requestFocus();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.0),
      child: GestureDetector(
        onTapDown: (TapDownDetails details) async {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          double totalTasksHeight = _totalTasksHeight;
          if (localPosition.dy > totalTasksHeight) {
            if (_tasks.isNotEmpty && _tasks.last['msg'].isEmpty) {
              await _dbHelper.deleteItem(_tasks.last['id']);
              await _loadTasks();
              setState(() {});
              return;
            }
            _addNewTask();
          } else {}
        },
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (ctx, index) {
            final task = _tasks[index];
            _controllers[task['id']] ??= TextEditingController(text: task['msg']);
            _focusNodes[task['id']] ??= FocusNode();
            _hoverStates[index] ??= false;

            TextField field = TextField(
              controller: _controllers[task['id']],
              focusNode: _focusNodes[task['id']],
              style: TextStyle(color: (_hoverStates[index] ?? false) ? Colors.orange : Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: task["msg"] ?? "",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: -13),
                isDense: true,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onChanged: (value) async {
                await _dbHelper.updateTask(task['id'], value);
                await _loadTasks();
                setState(() {});
              },
              textInputAction: TextInputAction.done,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _hoverStates[index] = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hoverStates[index] = false;
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.radio_button_off,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: field,
                        ),
                      ],
                    ),
                    Positioned(
                      right: 10,
                      top: -12,
                      child: AnimatedOpacity(
                        opacity: (_hoverStates[index] ?? false) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 100),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.task_alt,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _dbHelper.updateTaskState(task['id'], true);
                                _loadTasks();
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _dbHelper.deleteItem(task['id']);
                                _loadTasks();
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DoneList extends StatefulWidget {
  const DoneList({super.key});

  @override
  State<DoneList> createState() => _DoneListState();
}

class _DoneListState extends State<DoneList> {
  TextStyle taskStyle = const TextStyle(
    fontSize: 20,
    color: Colors.white,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w100,
  );

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _tasks = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    List<Map<String, dynamic>> tasks = await _dbHelper.getItems().then((task) {
      return task.where((val) => val['isDone'] == 1).toList();
    });
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.0),
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (ctx, index) {
          final task = _tasks[index];
          _controllers[task['id']] ??= TextEditingController(text: task['msg']);
          _focusNodes[task['id']] ??= FocusNode();
          _hoverStates[index] ??= false;

          TextField field = TextField(
            controller: _controllers[task['id']],
            focusNode: _focusNodes[task['id']],
            style: TextStyle(color: (_hoverStates[index] ?? false) ? Colors.orange : Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: task["msg"] ?? "",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: -13),
              isDense: true,
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MouseRegion(
              onEnter: (_) {
                setState(() {
                  _hoverStates[index] = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _hoverStates[index] = false;
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: field,
                      ),
                    ],
                  ),
                  Positioned(
                    right: 10,
                    top: -12,
                    child: AnimatedOpacity(
                      opacity: (_hoverStates[index] ?? false) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 100),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.settings_backup_restore,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _dbHelper.updateTaskState(task['id'], false);
                              _loadTasks();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _dbHelper.deleteItem(task['id']);
                              _loadTasks();
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database?> _initDatabase() async {
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, 'todo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        msg TEXT,
        isDone INTEGER
      )
    ''');
  }

  Future<int> insertItem(String task, int isDone) async {
    Database db = await database;
    return await db.insert('task', {'msg': task, 'isDone': isDone});
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    Database db = await database;
    return await db.query("task");
  }

  Future<int> deleteItem(int id) async {
    Database db = await database;
    return db.delete("task", where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    Database db = await database;
    db.delete("task", where: null);
  }

  Future<int> updateTask(int id, String newTask) async {
    Database db = await database;
    return await db.update(
      "task",
      {'msg': newTask},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTaskState(int id, bool isDone) async {
    Database db = await database;
    await db.update(
      "task",
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class SettingPage extends StatefulWidget {
  SettingPage({super.key, required this.opacity});
  ValueNotifier<double> opacity;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "背景透明度:",
                style: TextStyle(color: Colors.white),
              ),
              Slider(
                value: widget.opacity.value,
                label: widget.opacity.value.toStringAsFixed(1),
                onChanged: (double data) {
                  setState(() {
                    widget.opacity.value = data;
                  });
                },
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Center(
            child: Column(
              children: [
                TextButton(
                  style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context);
                  },
                  child: Text(
                    "清除所有数据",
                    style: GoogleFonts.notoSansSc(),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextButton(
                  style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
                  onPressed: () {
                    windowManager.close();
                  },
                  child: Text(
                    "退出",
                    style: GoogleFonts.notoSansSc(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("确认删除"),
          content: const Text("您确定要清除所有记录吗？此操作不可撤销！"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
              child: Text(
                "取消",
                style: GoogleFonts.notoSansSc(),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 关闭对话框
                await _dbHelper.deleteAll(); // 执行删除操作
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                    "所有记录已清除",
                    style: GoogleFonts.notoSansSc(),
                  )),
                );
              },
              child: Text(
                "确认",
                style: GoogleFonts.notoSansSc(),
              ),
            ),
          ],
        );
      },
    );
  }
}
