import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:todo/task.dart';
import 'package:todo/task_store.dart';
import 'log.dart';

enum TaskhandleFlag {
  COMPLETE,
  DELETE,
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  bool _showInputField = false;
  List<Task> _tasks = [];

  final TextEditingController _textInputController = TextEditingController();

  int _editIndex = -1;
  bool _editIsCompleted = false;
  final List<TextEditingController> _textEditControllers = [];

  final ValueNotifier<bool> _taskIconNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _taskIndexNotifier = ValueNotifier<int>(-1);
  final ValueNotifier<int> _taskEditNotifier = ValueNotifier<int>(-1);

  @override
  void dispose() {
    _taskIconNotifier.dispose();
    super.dispose();
  }

  void _handleTask(TaskhandleFlag flag, int index) {
    switch (flag) {
      case TaskhandleFlag.COMPLETE:
        {
          hyLog("MMMM: ", StackTrace.current);
          TaskStore.getInstance().editTask(uuid: _tasks[index].id, desc: _tasks[index].desc, isComplete: true);
          break;
        }
      case TaskhandleFlag.DELETE:
        {
          hyLog("MMMM: ", StackTrace.current);
          TaskStore.getInstance().deleteTask(_tasks[index].id);
          break;
        }

      default:
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print("_TodoPageState build");

    _tasks = TaskStore.getInstance().getTasks(false);

    _textEditControllers.clear();
    _tasks.forEach((e) {
      _textEditControllers.add(TextEditingController(text: e.desc));
    });

    return GestureDetector(
      onTapDown: (details) {
        hyLog("MMMM: ", StackTrace.current);
        if (_showInputField) {
          hyLog("MMMM: ", StackTrace.current);
          if (_textInputController.text.isNotEmpty) {
            hyLog("MMMM: ", StackTrace.current);
            TaskStore.getInstance().add(_textInputController.text.trim());
            _textInputController.clear();
          }
          hyLog("MMMM: ", StackTrace.current);
        } else if (!_showInputField && !_editIsCompleted) {
          hyLog("MMMM: ", StackTrace.current);
          if (_editIndex != -1) {
            hyLog("MMMM: ", StackTrace.current);
            TaskStore.getInstance()
                .editTask(uuid: _tasks[_editIndex].id, desc: _textEditControllers[_editIndex].text.trim());
            _editIndex = -1;
            _taskEditNotifier.value = -1;
          }
          hyLog("MMMM: ", StackTrace.current);
        }

        hyLog("MMMM: ", StackTrace.current);
        setState(() {
          _tasks = TaskStore.getInstance().getTasks(false);
          _showInputField = !_showInputField;
        });
        hyLog("MMMM: ", StackTrace.current);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        child: ListView.builder(
          itemCount: _tasks.length + (_showInputField ? 1 : 0),
          itemBuilder: (context, index) {
            hyLog("MMMM: ", StackTrace.current);
            if (index == _tasks.length && _showInputField) {
              print("_TodoPageState index == _tasks.length && _showInputField");
              return TextField(
                controller: _textInputController,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    TaskStore.getInstance().add(value.trim());
                    _textInputController.clear();
                    setState(() {
                      _showInputField = false;
                    });
                  }
                },
              );
            }

            return MouseRegion(
              onEnter: (event) {
                _taskIconNotifier.value = true;
                _taskIndexNotifier.value = index;
              },
              onExit: (event) {
                _taskIconNotifier.value = false;
                _taskIndexNotifier.value = -1;
              },
              child: Stack(
                children: [
                  TextField(
                    controller: _textEditControllers[index],
                    onSubmitted: (value) {
                      TaskStore.getInstance().editTask(uuid: _tasks[index].id, desc: value);
                      _editIsCompleted = true;
                      setState(() {});
                    },
                    onTap: () {
                      _editIndex = index;
                      _taskEditNotifier.value = index;
                    },
                  ),
                  TaskIcons(
                    highlightNotifier: _taskIconNotifier,
                    index: index,
                    indexNotifier: _taskIndexNotifier,
                    editNotifier: _taskEditNotifier,
                    handleTask: _handleTask,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TaskItem extends StatefulWidget {
  const TaskItem({super.key});

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TaskInputItem extends StatefulWidget {
  const TaskInputItem({super.key});

  @override
  State<TaskInputItem> createState() => _TaskInputItemState();
}

class _TaskInputItemState extends State<TaskInputItem> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TaskIcons extends StatefulWidget {
  const TaskIcons(
      {super.key,
      required this.highlightNotifier,
      required this.index,
      required this.indexNotifier,
      required this.editNotifier,
      required this.handleTask});
  final int index;
  final ValueNotifier<bool> highlightNotifier;
  final ValueNotifier<int> indexNotifier;
  final ValueNotifier<int> editNotifier;
  final Function(TaskhandleFlag, int) handleTask;

  @override
  State<TaskIcons> createState() => _TaskIconsState();
}

class _TaskIconsState extends State<TaskIcons> {
  @override
  void initState() {
    super.initState();
    widget.highlightNotifier.addListener(_handleHighlightChange);
    widget.indexNotifier.addListener(_handleHighlightChange);
    widget.editNotifier.addListener(_handleHighlightChange);
  }

  @override
  void dispose() {
    widget.highlightNotifier.removeListener(_handleHighlightChange);
    widget.indexNotifier.removeListener(_handleHighlightChange);
    widget.editNotifier.removeListener(_handleHighlightChange);
    super.dispose();
  }

  void _handleHighlightChange() {
    setState(() {
      // Just calling setState to rebuild the widget
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      child: Row(
        children: [
          if (widget.highlightNotifier.value &&
              (widget.indexNotifier.value == widget.index) &&
              (widget.editNotifier.value != widget.index))
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                widget.handleTask(TaskhandleFlag.COMPLETE, widget.index);
              },
            ),
          if (widget.highlightNotifier.value &&
              (widget.indexNotifier.value == widget.index) &&
              (widget.editNotifier.value != widget.index))
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                widget.handleTask(TaskhandleFlag.DELETE, widget.index);
              },
            ),
        ],
      ),
    );
  }
}
