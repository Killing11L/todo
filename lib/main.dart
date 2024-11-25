import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WindowOptions windowOptions = const WindowOptions(
    size: Size(350, 400),
    minimumSize: Size(350, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();
  });

  if (kIsWeb) {
    print("web");
  } else {
    print("windows");
  }

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
      home: GestureDetector(
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
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.isEnter});
  final String title;
  final ValueNotifier<bool> isEnter;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isTodoSelected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black.withOpacity(0.35),
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isTodoSelected = true;
                              });
                            },
                            child: Text(
                              "ToDo",
                              style: TextStyle(
                                fontSize: isTodoSelected ? 35 : 25,
                                decoration: TextDecoration.none,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isTodoSelected = false;
                              });
                            },
                            child: Text(
                              "Done",
                              style: TextStyle(
                                fontSize: isTodoSelected ? 25 : 35,
                                decoration: TextDecoration.none,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEnter)
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                          iconSize: 30,
                          onPressed: () {},
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
            child: isTodoSelected ? const TodoList() : const DoneList(),
          ),
        ],
      ),
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
            if (_tasks.last['msg'].isEmpty) {
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
                contentPadding: const EdgeInsets.only(top: -15),
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
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4), // 控制背景的大小
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8), // 背景色
                              shape: BoxShape.circle, // 圆形背景
                            ),
                            child: const Icon(
                              Icons.task_alt,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                          onPressed: () {
                            _dbHelper.updateTaskState(task['id'], true);
                            _loadTasks();
                          },
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
              contentPadding: const EdgeInsets.only(top: -15),
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
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4), // 控制背景的大小
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8), // 背景色
                            shape: BoxShape.circle, // 圆形背景
                          ),
                          child: const Icon(
                            Icons.settings_backup_restore,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          _dbHelper.updateTaskState(task['id'], false);
                          _loadTasks();
                        },
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

    await db.insert('task', {'msg': "task1", 'isDone': 0});
    await db.insert('task', {'msg': "task2", 'isDone': 0});
    await db.insert('task', {'msg': "task3", 'isDone': 0});
    await db.insert('task', {'msg': "task4", 'isDone': 1});
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
