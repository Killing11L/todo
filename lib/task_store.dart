import 'package:todo/task.dart';
import 'package:uuid/uuid.dart';

class TaskStore {
  static TaskStore? _instance;
  var _uuid = Uuid();

  TaskStore._internal() {
    _tasks.addAll([
      Task(id: getUuid(), desc: "task1", isCompleted: false),
      Task(id: getUuid(), desc: "task2", isCompleted: false),
    ]);
  }

  static TaskStore getInstance() {
    _instance ??= TaskStore._internal();
    return _instance!;
  }

  List<Task> _tasks = [];

  void add(String taskDesc) {
    _tasks.add(Task(id: getUuid(), desc: taskDesc, isCompleted: false));
  }

  void deleteTask(String uuid) {
    _tasks.removeWhere((element) => element.id == uuid);
  }

  void editTask({required String uuid, required String desc, bool isComplete = false}) {
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].id == uuid) {
        _tasks[i] = Task(id: uuid, desc: desc, isCompleted: isComplete);
        break;
      }
    }
  }

  String getUuid() {
    return _uuid.v1();
  }

  List<Task> getTasks(bool isCompleted) {
    return _tasks.where((e) => e.isCompleted == isCompleted).toList();
  }
}
