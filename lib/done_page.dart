import 'package:flutter/material.dart';
import 'package:todo/task.dart';
import 'package:todo/task_store.dart';

class DonePage extends StatefulWidget {
  const DonePage({super.key});

  @override
  State<DonePage> createState() => _DonePageState();
}

class _DonePageState extends State<DonePage> {
  List<Task> _tasks = [];

  @override
  Widget build(BuildContext context) {
    _tasks = TaskStore.getInstance().getTasks(true);
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(itemCount: _tasks.length,
      itemBuilder: (context, index) {
        return Text(_tasks[index].desc);
      },)
    );
  }
}