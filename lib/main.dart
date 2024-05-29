import 'package:flutter/material.dart';
import 'package:todo/done_page.dart';
import 'package:todo/todo_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the TabController when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TabBar(
          controller: _tabController, // Add this line
          tabs: const [
            Tab(text: "TODO"),
            Tab(text: "DONE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TodoPage(),
          DonePage(),
        ],
      ),
    );
  }
}
