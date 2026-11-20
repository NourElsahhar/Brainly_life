import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/field_label.dart';
import 'package:flutter/material.dart';

/// The checklist part of the task form: the subtasks, then a box to add one.
class SubtasksEditor extends StatefulWidget {
  const SubtasksEditor({
    super.key,
    required this.subtasks,
    required this.canAdd,
    required this.enabled,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  final List<Subtask> subtasks;

  /// false when the task already has the most subtasks allowed.
  final bool canAdd;
  final bool enabled;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onRemove;

  @override
  State<SubtasksEditor> createState() => _SubtasksEditorState();
}

class _SubtasksEditorState extends State<SubtasksEditor> {
  final _newSubtask = TextEditingController();

  @override
  void dispose() {
    _newSubtask.dispose();
    super.dispose();
  }

  void _add() {
    final title = _newSubtask.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(title);
    _newSubtask.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canType = widget.enabled && widget.canAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel('Subtasks (${widget.subtasks.length}/${Task.maxSubtasks})'),
        for (final subtask in widget.subtasks)
          Row(
            children: [
              Checkbox(
                value: subtask.done,
                onChanged: widget.enabled
                    ? (_) => widget.onToggle(subtask.id)
                    : null,
              ),
              Expanded(
                child: Text(
                  subtask.title,
                  style: context.text.bodyMedium?.copyWith(
                    color: subtask.done ? p.textTertiary : p.textPrimary,
                    decoration: subtask.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove subtask',
                icon: Icon(Icons.close_rounded, color: p.iconMuted),
                onPressed: widget.enabled
                    ? () => widget.onRemove(subtask.id)
                    : null,
              ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newSubtask,
                enabled: canType,
                maxLength: Task.maxTitleLength,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.canAdd
                      ? 'Add a subtask'
                      : 'You reached ${Task.maxSubtasks} subtasks',
                  counterText: '',
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            IconButton(
              tooltip: 'Add subtask',
              icon: Icon(Icons.add_circle_rounded, color: p.primary),
              onPressed: canType ? _add : null,
            ),
          ],
        ),
      ],
    );
  }
}
