import 'package:flutter/material.dart';
import '../../widgets/teacher_home.dart';
import '../../widgets/qr_generate_page.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});
  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;
  final pages = const [TeacherHome(), QrGeneratePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher')),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'QR'),
        ],
      ),
    );
  }
}

