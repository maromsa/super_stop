import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_story.dart';
import '../providers/habit_story_provider.dart';

class HabitStoryBuilderScreen extends StatefulWidget {
  const HabitStoryBuilderScreen({super.key});

  @override
  State<HabitStoryBuilderScreen> createState() => _HabitStoryBuilderScreenState();
}

class _HabitStoryBuilderScreenState extends State<HabitStoryBuilderScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<HabitStoryProvider>();
    _controller.text = provider.heroName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('בניית קומיקס ההרגלים'),
      ),
      body: Consumer<HabitStoryProvider>(
        builder: (context, provider, _) {
          final chapters = provider.chapters;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'שם הגיבור/ה בסיפור',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => provider.renameHero(value),
                ),
                const SizedBox(height: 12),
                Text(
                  'פרקים שנאספו: ${chapters.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return _ChapterCard(chapter: chapter, heroName: provider.heroName);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<HabitStoryProvider>().renameHero(_controller.text),
        icon: const Icon(Icons.save),
        label: const Text('שמור שם'),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.heroName});

  final HabitStoryChapter chapter;
  final String heroName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chapter.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(label: Text('יום ${chapter.dayIndex}')),
              ],
            ),
            const SizedBox(height: 8),
            Text(chapter.body.replaceAll('{hero}', heroName)),
          ],
        ),
      ),
    );
  }
}
