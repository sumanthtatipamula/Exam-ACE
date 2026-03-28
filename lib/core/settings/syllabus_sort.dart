import 'package:exam_ace/core/settings/syllabus_sort_mode.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/models/topic.dart';

int _cmpIdCh(Chapter a, Chapter b) => a.id.compareTo(b.id);
int _cmpIdT(Topic a, Topic b) => a.id.compareTo(b.id);

/// Sorts [chapters] in place according to [mode].
void sortChapters(List<Chapter> chapters, SyllabusSortMode mode) {
  switch (mode) {
    case SyllabusSortMode.creation:
      sortChaptersByUserCreationOrder(chapters);
      break;
    case SyllabusSortMode.targetDate:
      chapters.sort((a, b) {
        final da = a.date;
        final db = b.date;
        if (da != null && db != null) {
          final c = da.compareTo(db);
          if (c != 0) return c;
          return _cmpIdCh(a, b);
        }
        if (da != null) return -1;
        if (db != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case SyllabusSortMode.nameAZ:
      chapters.sort((a, b) {
        final c =
            a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (c != 0) return c;
        return _cmpIdCh(a, b);
      });
      break;
    case SyllabusSortMode.progressHigh:
      chapters.sort((a, b) {
        final c = b.progress.compareTo(a.progress);
        if (c != 0) return c;
        return _cmpIdCh(a, b);
      });
      break;
    case SyllabusSortMode.progressLow:
      chapters.sort((a, b) {
        final c = a.progress.compareTo(b.progress);
        if (c != 0) return c;
        return _cmpIdCh(a, b);
      });
      break;
  }
}

/// Sorts [topics] in place according to [mode].
void sortTopics(List<Topic> topics, SyllabusSortMode mode) {
  switch (mode) {
    case SyllabusSortMode.creation:
      sortTopicsByUserCreationOrder(topics);
      break;
    case SyllabusSortMode.targetDate:
      topics.sort((a, b) {
        final da = a.date;
        final db = b.date;
        if (da != null && db != null) {
          final c = da.compareTo(db);
          if (c != 0) return c;
          return _cmpIdT(a, b);
        }
        if (da != null) return -1;
        if (db != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case SyllabusSortMode.nameAZ:
      topics.sort((a, b) {
        final c =
            a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (c != 0) return c;
        return _cmpIdT(a, b);
      });
      break;
    case SyllabusSortMode.progressHigh:
      topics.sort((a, b) {
        final c = b.progress.compareTo(a.progress);
        if (c != 0) return c;
        return _cmpIdT(a, b);
      });
      break;
    case SyllabusSortMode.progressLow:
      topics.sort((a, b) {
        final c = a.progress.compareTo(b.progress);
        if (c != 0) return c;
        return _cmpIdT(a, b);
      });
      break;
  }
}

/// Chapters with [Chapter.createdAt] first (oldest → newest), then legacy rows
/// without it (sorted by name for a stable fallback).
void sortChaptersByUserCreationOrder(List<Chapter> chapters) {
  chapters.sort((a, b) {
    final ca = a.createdAt;
    final cb = b.createdAt;
    if (ca != null && cb != null) {
      final t = ca.compareTo(cb);
      if (t != 0) return t;
      return a.id.compareTo(b.id);
    }
    if (ca != null) return 1;
    if (cb != null) return -1;
    return a.name.compareTo(b.name);
  });
}

/// Same rules as [sortChaptersByUserCreationOrder] for topics.
void sortTopicsByUserCreationOrder(List<Topic> topics) {
  topics.sort((a, b) {
    final ta = a.createdAt;
    final tb = b.createdAt;
    if (ta != null && tb != null) {
      final c = ta.compareTo(tb);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    }
    if (ta != null) return 1;
    if (tb != null) return -1;
    return a.name.compareTo(b.name);
  });
}
