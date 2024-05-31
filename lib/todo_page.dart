import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:todo/task.dart';
import 'package:todo/task_store.dart';

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
  int _isHoveredIndex = -1;

  final ValueNotifier<bool> _taskIconNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _taskIndexNotifier = ValueNotifier<int>(-1);

  @override
  void dispose() {
    _taskIconNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tasks = TaskStore.getInstance().getTasks(false);

    _textEditControllers.clear();
    _tasks.forEach((e) {
      _textEditControllers.add(TextEditingController(text: e.desc));
    });

    print('_showInputField: ${_showInputField}');
    return GestureDetector(
      onTapDown: (details) {
        if (_showInputField) {
          if (_textInputController.text.isNotEmpty) {
            print('add new task ${_textInputController.text}');
            TaskStore.getInstance().add(_textInputController.text.trim());
            _textInputController.clear();
          }
        } else if (!_showInputField && !_editIsCompleted) {
          if (_editIndex != -1) {
            print('edit task ${_textEditControllers[_editIndex].text}');
            TaskStore.getInstance().editTask(
                uuid: _tasks[_editIndex].id,
                desc: _textEditControllers[_editIndex].text.trim());
          }
          _editIndex = -1;
        }

        setState(() {
          _tasks = TaskStore.getInstance().getTasks(false);
          _showInputField = !_showInputField;
        });
        print('Clicked on empty, ${_showInputField}');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: _tasks.length + (_showInputField ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _tasks.length && _showInputField) {
              return TextField(
                controller: _textInputController,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    print(
                        'onSubmitted add new task ${_textInputController.text}');
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
                print('_TodoPageState onEnter');
                _taskIconNotifier.value = true;
                _taskIndexNotifier.value = index;
              },
              onExit: (event) {
                print('_TodoPageState onExit');
                _taskIconNotifier.value = false;
                _taskIndexNotifier.value = -1;
              },
              child: Stack(
                children: [
                  TextField(
                    controller: _textEditControllers[index],
                    onSubmitted: (value) {
                      print('MMMMMM onSubmitted ${value}');
                      TaskStore.getInstance()
                          .editTask(uuid: _tasks[index].id, desc: value);
                      _editIsCompleted = true;
                      setState(() {});
                    },
                    onTap: () {
                      _editIndex = index;
                    },
                  ),
                  TaskIcons(
                    highlightNotifier: _taskIconNotifier,
                    index: index,
                    indexNotifier: _taskIndexNotifier,
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
      required this.indexNotifier});
  final int index;
  final ValueNotifier<bool> highlightNotifier;
  final ValueNotifier<int> indexNotifier;

  @override
  State<TaskIcons> createState() => _TaskIconsState();
}

class _TaskIconsState extends State<TaskIcons> {
  @override
  void initState() {
    super.initState();
    widget.highlightNotifier.addListener(_handleHighlightChange);
  }

  @override
  void dispose() {
    widget.highlightNotifier.removeListener(_handleHighlightChange);
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
          if (widget.highlightNotifier.value && (widget.indexNotifier.value == widget.index))
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {});
              },
            ),
          if (widget.highlightNotifier.value && (widget.indexNotifier.value == widget.index))
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
