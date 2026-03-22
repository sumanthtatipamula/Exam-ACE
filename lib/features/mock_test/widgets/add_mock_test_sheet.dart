import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/mock_test/models/mock_test.dart';
import 'package:exam_ace/features/mock_test/providers/mock_test_provider.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/models/topic.dart';

class AddMockTestSheet extends ConsumerStatefulWidget {
  /// When set, the sheet opens in edit mode and updates the existing document.
  final MockTest? existing;

  const AddMockTestSheet({super.key, this.existing});

  bool get isEditing => existing != null;

  @override
  ConsumerState<AddMockTestSheet> createState() => _AddMockTestSheetState();
}

class _AddMockTestSheetState extends ConsumerState<AddMockTestSheet> {
  final _titleController = TextEditingController();
  final _marksController = TextEditingController();
  final _totalController = TextEditingController();
  DateTime _date = DateTime.now();

  LinkType _linkType = LinkType.none;
  Subject? _selectedSubject;
  Chapter? _selectedChapter;
  Topic? _selectedTopic;

  /// Whether subject/chapter/topic dropdowns have been restored from [existing].
  bool _linksSynced = false;

  int _syncLinkAttempts = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _marksController.text = '${e.marksObtained}';
      _totalController.text = '${e.totalMarks}';
      _date = e.date;
      _linkType = e.linkType;
      if (e.linkType == LinkType.none) {
        _linksSynced = true;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _trySyncLinks());
  }

  /// Resolves dropdown selections from Firestore IDs; retries while streams load.
  void _trySyncLinks() {
    if (!mounted) return;
    if (_resolveSyncFromExisting()) return;
    if (_syncLinkAttempts++ > 120) {
      if (mounted) setState(() => _linksSynced = true);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _trySyncLinks());
  }

  /// Returns `true` when syncing is done (success or given up).
  bool _resolveSyncFromExisting() {
    final e = widget.existing;
    if (e == null || _linksSynced) return true;
    if (e.linkType == LinkType.none) {
      _linksSynced = true;
      return true;
    }

    final subjects = ref.read(subjectsStreamProvider).valueOrNull;
    if (subjects == null) return false;

    Subject? subj;
    if (e.linkedSubjectId != null) {
      for (final s in subjects) {
        if (s.id == e.linkedSubjectId) {
          subj = s;
          break;
        }
      }
    }

    switch (e.linkType) {
      case LinkType.subject:
        setState(() {
          _selectedSubject = subj;
          _linksSynced = true;
        });
        return true;
      case LinkType.chapter:
      case LinkType.topic:
        if (subj == null) {
          setState(() => _linksSynced = true);
          return true;
        }
        final chs = ref.read(chaptersStreamProvider(subj.id)).valueOrNull;
        if (chs == null) return false;

        Chapter? ch;
        if (e.linkedChapterId != null) {
          for (final c in chs) {
            if (c.id == e.linkedChapterId) {
              ch = c;
              break;
            }
          }
        }

        if (e.linkType == LinkType.chapter) {
          setState(() {
            _selectedSubject = subj;
            _selectedChapter = ch;
            _linksSynced = true;
          });
          return true;
        }

        if (ch == null) {
          setState(() {
            _selectedSubject = subj;
            _linksSynced = true;
          });
          return true;
        }

        final tops = ref
            .read(topicsStreamProvider((
              subjectId: subj.id,
              chapterId: ch.id,
            )))
            .valueOrNull;
        if (tops == null) return false;

        Topic? top;
        if (e.linkedTopicId != null) {
          for (final t in tops) {
            if (t.id == e.linkedTopicId) {
              top = t;
              break;
            }
          }
        }
        setState(() {
          _selectedSubject = subj;
          _selectedChapter = ch;
          _selectedTopic = top;
          _linksSynced = true;
        });
        return true;
      case LinkType.none:
        return true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _marksController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  /// [DropdownButtonFormField] matches [value] with [items] by `==`. [Subject] has
  /// reference equality, so after Firestore rebuilds, the stored selection can be
  /// a stale instance and **not** match any item — assert/crash. Resolve by id.
  Subject? _resolveSubject(List<Subject> subjects) {
    final id = _selectedSubject?.id;
    if (id == null) return null;
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Chapter? _resolveChapter(List<Chapter> chapters) {
    final id = _selectedChapter?.id;
    if (id == null) return null;
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  Topic? _resolveTopic(List<Topic> topics) {
    final id = _selectedTopic?.id;
    if (id == null) return null;
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final marks = int.tryParse(_marksController.text.trim()) ?? 0;
    final total = int.tryParse(_totalController.text.trim()) ?? 0;
    if (total <= 0) return;

    if (marks > total) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        'Marks obtained cannot be greater than total marks.',
      );
      return;
    }

    String? linkedName;
    String? linkedSubjectId;
    String? linkedChapterId;
    String? linkedTopicId;

    switch (_linkType) {
      case LinkType.subject:
        linkedSubjectId = _selectedSubject?.id;
        linkedName = _selectedSubject?.name;
        break;
      case LinkType.chapter:
        linkedSubjectId = _selectedSubject?.id;
        linkedChapterId = _selectedChapter?.id;
        linkedName = _selectedChapter?.name;
        break;
      case LinkType.topic:
        linkedSubjectId = _selectedSubject?.id;
        linkedChapterId = _selectedChapter?.id;
        linkedTopicId = _selectedTopic?.id;
        linkedName = _selectedTopic?.name;
        break;
      case LinkType.none:
        break;
    }

    final repo = ref.read(mockTestRepositoryProvider);
    final test = MockTest(
      id: widget.existing?.id ?? '',
      title: _titleController.text.trim(),
      marksObtained: marks,
      totalMarks: total,
      date: _date,
      linkType: _linkType,
      linkedSubjectId: linkedSubjectId,
      linkedChapterId: linkedChapterId,
      linkedTopicId: linkedTopicId,
      linkedName: linkedName,
    );

    try {
      if (widget.existing != null) {
        await repo.update(test);
      } else {
        await repo.add(test);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.existing != null) {
        showSuccessSnackBar(context, 'Mock test updated');
      } else {
        showSuccessSnackBar(context, 'Mock test added');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          widget.existing != null
              ? 'Failed to update: $e'
              : 'Failed to add: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects =
        ref.watch(subjectsStreamProvider).valueOrNull ?? [];

    List<Chapter> chapters = [];
    if (_selectedSubject != null) {
      chapters = ref
              .watch(chaptersStreamProvider(_selectedSubject!.id))
              .valueOrNull ??
          [];
    }

    List<Topic> topics = [];
    if (_selectedSubject != null && _selectedChapter != null) {
      topics = ref
              .watch(topicsStreamProvider((
                subjectId: _selectedSubject!.id,
                chapterId: _selectedChapter!.id,
              )))
              .valueOrNull ??
          [];
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEditing ? 'Edit Mock Test' : 'Add Mock Test',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Test Name (optional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _marksController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Marks Obtained *',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Marks *',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(DateFormat.yMMMd().format(_date)),
            ),
            const SizedBox(height: 16),
            Text('Link to (optional)',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            SegmentedButton<LinkType>(
              segments: const [
                ButtonSegment(value: LinkType.none, label: Text('None')),
                ButtonSegment(
                    value: LinkType.subject, label: Text('Subject')),
                ButtonSegment(
                    value: LinkType.chapter, label: Text('Chapter')),
                ButtonSegment(value: LinkType.topic, label: Text('Topic')),
              ],
              selected: {_linkType},
              onSelectionChanged: (v) {
                setState(() {
                  _linkType = v.first;
                  _selectedSubject = null;
                  _selectedChapter = null;
                  _selectedTopic = null;
                });
              },
              style: SegmentedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            if (_linkType != LinkType.none) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Subject>(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  isDense: true,
                ),
                value: _resolveSubject(subjects),
                items: subjects
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedSubject = v;
                    _selectedChapter = null;
                    _selectedTopic = null;
                  });
                },
              ),
            ],
            if (_linkType == LinkType.chapter ||
                _linkType == LinkType.topic) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Chapter>(
                decoration: const InputDecoration(
                  labelText: 'Chapter',
                  isDense: true,
                ),
                value: _resolveChapter(chapters),
                items: chapters
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.name)))
                    .toList(),
                onChanged: _selectedSubject == null
                    ? null
                    : (v) {
                        setState(() {
                          _selectedChapter = v;
                          _selectedTopic = null;
                        });
                      },
              ),
            ],
            if (_linkType == LinkType.topic) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Topic>(
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  isDense: true,
                ),
                value: _resolveTopic(topics),
                items: topics
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.name)))
                    .toList(),
                onChanged: _selectedChapter == null
                    ? null
                    : (v) => setState(() => _selectedTopic = v),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
