import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NotesEditorScreen extends StatefulWidget {
  final String title;
  final String initialContent;
  final ValueChanged<String> onSave;

  const NotesEditorScreen({
    super.key,
    required this.title,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<NotesEditorScreen> createState() => _NotesEditorScreenState();
}

class _NotesEditorScreenState extends State<NotesEditorScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasChanges = false;
  /// When true, show rendered Markdown (read-only). Edit mode shows raw text + toolbar.
  late bool _previewMode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _focusNode = FocusNode();
    _previewMode = widget.initialContent.trim().isNotEmpty;
    _controller.addListener(() {
      if (!_hasChanges && _controller.text != widget.initialContent) {
        setState(() => _hasChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(_controller.text);
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes saved'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content:
            const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () {
              _save();
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // --- Toolbar actions ---

  void _wrapSelection(String prefix, String suffix) {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid) return;

    final selected = sel.textInside(text);
    final before = text.substring(0, sel.start);
    final after = text.substring(sel.end);

    final replacement = '$prefix$selected$suffix';
    _controller.text = '$before$replacement$after';
    _controller.selection = TextSelection.collapsed(
      offset: sel.start + prefix.length + selected.length,
    );
    _focusNode.requestFocus();
  }

  void _insertAtLineStart(String prefix) {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid) return;

    // lastIndexOf's second arg must be >= 0; when cursor is at 0, sel.start - 1 is invalid.
    final searchEnd = sel.start > 0 ? sel.start - 1 : 0;
    final lineStart = text.lastIndexOf('\n', searchEnd) + 1;
    final before = text.substring(0, lineStart);
    final after = text.substring(lineStart);

    _controller.text = '$before$prefix$after';
    _controller.selection = TextSelection.collapsed(
      offset: sel.start + prefix.length,
    );
    _focusNode.requestFocus();
  }

  void _insertText(String insert) {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid) return;

    final before = text.substring(0, sel.start);
    final after = text.substring(sel.end);

    _controller.text = '$before$insert$after';
    _controller.selection = TextSelection.collapsed(
      offset: sel.start + insert.length,
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _previewMode = !_previewMode;
                  if (_previewMode) {
                    _focusNode.unfocus();
                  }
                });
              },
              icon: Icon(
                _previewMode ? Icons.edit_rounded : Icons.visibility_rounded,
              ),
              tooltip: _previewMode ? 'Edit' : 'Preview',
            ),
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            IconButton(
              onPressed: _hasChanges ? _save : null,
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save',
            ),
          ],
        ),
        body: _previewMode
            ? _buildMarkdownPreview(theme, colorScheme)
            : Column(
                children: [
                  _Toolbar(
                    colorScheme: colorScheme,
                    onBold: () => _wrapSelection('**', '**'),
                    onItalic: () => _wrapSelection('_', '_'),
                    onStrikethrough: () => _wrapSelection('~~', '~~'),
                    onHeading: () => _insertAtLineStart('# '),
                    onSubheading: () => _insertAtLineStart('## '),
                    onBullet: () => _insertAtLineStart('• '),
                    onNumbered: () => _insertAtLineStart('1. '),
                    onCheckbox: () => _insertAtLineStart('☐ '),
                    onChecked: () => _insertAtLineStart('☑ '),
                    onDivider: () => _insertText('\n---\n'),
                    onCode: () => _wrapSelection('`', '`'),
                    onHighlight: () => _wrapSelection('==', '=='),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          letterSpacing: 0.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Start writing your notes...',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMarkdownPreview(ThemeData theme, ColorScheme colorScheme) {
    final md = _controller.text.trim();
    if (md.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nothing to preview yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.7,
      letterSpacing: 0.2,
      color: colorScheme.onSurface,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: MarkdownBody(
          data: _controller.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: baseStyle,
            h1: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            h2: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            strong: baseStyle?.copyWith(fontWeight: FontWeight.w700),
            em: baseStyle?.copyWith(fontStyle: FontStyle.italic),
            code: baseStyle?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            blockquote: baseStyle?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            listBullet: baseStyle,
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrikethrough;
  final VoidCallback onHeading;
  final VoidCallback onSubheading;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;
  final VoidCallback onCheckbox;
  final VoidCallback onChecked;
  final VoidCallback onDivider;
  final VoidCallback onCode;
  final VoidCallback onHighlight;

  const _Toolbar({
    required this.colorScheme,
    required this.onBold,
    required this.onItalic,
    required this.onStrikethrough,
    required this.onHeading,
    required this.onSubheading,
    required this.onBullet,
    required this.onNumbered,
    required this.onCheckbox,
    required this.onChecked,
    required this.onDivider,
    required this.onCode,
    required this.onHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onTap: onBold,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onTap: onItalic,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.strikethrough_s_rounded,
              tooltip: 'Strikethrough',
              onTap: onStrikethrough,
              colorScheme: colorScheme,
            ),
            _divider(),
            _ToolButton(
              icon: Icons.title_rounded,
              tooltip: 'Heading',
              onTap: onHeading,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.text_fields_rounded,
              tooltip: 'Subheading',
              onTap: onSubheading,
              colorScheme: colorScheme,
            ),
            _divider(),
            _ToolButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet list',
              onTap: onBullet,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.format_list_numbered_rounded,
              tooltip: 'Numbered list',
              onTap: onNumbered,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.check_box_outline_blank_rounded,
              tooltip: 'Checkbox',
              onTap: onCheckbox,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.check_box_rounded,
              tooltip: 'Checked',
              onTap: onChecked,
              colorScheme: colorScheme,
            ),
            _divider(),
            _ToolButton(
              icon: Icons.code_rounded,
              tooltip: 'Inline code',
              onTap: onCode,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.highlight_rounded,
              tooltip: 'Highlight',
              onTap: onHighlight,
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.horizontal_rule_rounded,
              tooltip: 'Divider',
              onTap: onDivider,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
