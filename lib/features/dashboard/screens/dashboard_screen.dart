import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/screens/home_screen.dart';
import 'package:exam_ace/features/home/widgets/daily_tasks.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/features/subjects/screens/subjects_screen.dart';
import 'package:exam_ace/features/subjects/widgets/add_subject_sheet.dart';
import 'package:exam_ace/features/exam_score/screens/exam_score_screen.dart';
import 'package:exam_ace/features/exam_score/widgets/add_exam_score_sheet.dart';
import 'package:exam_ace/features/mock_test/screens/mock_test_screen.dart';
import 'package:exam_ace/features/mock_test/widgets/add_mock_test_sheet.dart';
import 'package:exam_ace/features/profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    SubjectsScreen(),
    MockTestScreen(),
    ExamsScreen(),
    ProfileScreen(),
  ];

  PreferredSizeWidget? _appBarForIndex(int index) {
    return switch (index) {
      2 => AppBar(title: const Text('Mock Tests')),
      3 => AppBar(title: const Text('Exams')),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBarForIndex(_selectedIndex),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      floatingActionButton: switch (_selectedIndex) {
        0 => Consumer(
            builder: (context, ref, _) {
              return FloatingActionButton(
                onPressed: () {
                  final date = ref.read(homeSelectedDateProvider);
                  final repo = ref.read(tasksRepositoryProvider);
                  showAddTaskSheet(context, repo, date);
                },
                tooltip: 'New task',
                child: const Icon(Icons.playlist_add_rounded),
              );
            },
          ),
        1 => Consumer(
            builder: (context, ref, _) {
              return FloatingActionButton(
                onPressed: () {
                  final repo = ref.read(subjectsRepositoryProvider);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddSubjectSheet(
                      onSave: (name, imageUrl, date) {
                        repo.addSubject(
                          Subject(
                            id: '',
                            name: name,
                            imageUrl: imageUrl,
                            date: date,
                            createdAt: DateTime.now(),
                          ),
                        );
                      },
                    ),
                  );
                },
                tooltip: 'Add subject',
                child: const Icon(Icons.add_rounded),
              );
            },
          ),
        2 => FloatingActionButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddMockTestSheet(),
              );
            },
            tooltip: 'Add mock test',
            child: const Icon(Icons.add_rounded),
          ),
        3 => FloatingActionButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddExamSheet(),
              );
            },
            tooltip: 'Add exam',
            child: const Icon(Icons.add_rounded),
          ),
        _ => null,
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt_rounded),
            label: 'Mock Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'Exams',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
