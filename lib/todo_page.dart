import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    _tasks = TaskStore.getInstance().getTasks(false);

    _textEditControllers.clear();
    _tasks.forEach(
        (e) => _textEditControllers.add(TextEditingController(text: e.desc)));
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
            print('MMMMMM ${index}');
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
                if (_editIndex != -1) {
                  print('edit task ${_textEditControllers[_editIndex].text}');
                  TaskStore.getInstance().editTask(
                      uuid: _tasks[_editIndex].id,
                      desc: _textEditControllers[_editIndex].text.trim());
                  _editIndex = -1;
                }

                setState(() {
                  _isHoveredIndex = index;
                });
              },
              onExit: (event) {
                if (_editIndex != -1) {
                  print('edit task ${_textEditControllers[_editIndex].text}');
                  TaskStore.getInstance().editTask(
                      uuid: _tasks[_editIndex].id,
                      desc: _textEditControllers[_editIndex].text.trim());
                  _editIndex = -1;
                }
                setState(() {
                  _isHoveredIndex = -1;
                });
              },
              child: GestureDetector(
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
                    if (_isHoveredIndex == index)
                      Positioned(
                        right: 0,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                TaskStore.getInstance().editTask(
                                    uuid: _tasks[index].id,
                                    desc:
                                        _textEditControllers[index].text.trim(),
                                    isComplete: true);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                TaskStore.getInstance()
                                    .deleteTask(_tasks[index].id);
                              },
                            ),
                          ],
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
