/// Strip common Markdown syntax for one-line list previews (e.g. chapter notes tile).
String plainPreviewFromMarkdown(String markdown) {
  var s = markdown;
  s = s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'==(.+?)=='), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1]!);
  s = s.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^[☐☑]\s*', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^---+[\s]*$', multiLine: true), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
