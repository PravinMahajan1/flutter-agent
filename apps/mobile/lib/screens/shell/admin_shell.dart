import 'package:flutter/material.dart';
import '../../widgets/admin_home.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final pages = const [AdminHome()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Vision 2.0')),
            ListTile(leading: const Icon(Icons.analytics), title: const Text('Analytics'), onTap: () => setState(() => _index = 0)),
          ],
        ),
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: pages[_index]),
    );
  }
}

