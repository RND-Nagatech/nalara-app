import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../content/help_topics.dart';
import 'help_center_style.dart';

class HelpTopicCard extends StatelessWidget {
  final HelpTopic topic;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  const HelpTopicCard({
    super.key,
    required this.topic,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              key: ValueKey('help-toggle-${topic.id}'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.title,
                        style: HelpCenterStyle.body.copyWith(
                          color: expanded
                              ? HelpCenterStyle.green
                              : HelpCenterStyle.ink,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ExcludeSemantics(
                      child: AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          color: HelpCenterStyle.green,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    key: ValueKey('help-answer-${topic.id}'),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1, color: HelpCenterStyle.line),
                        const SizedBox(height: 14),
                        Text(topic.answer, style: HelpCenterStyle.body),
                        if (topic.steps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          for (final (index, step) in topic.steps.indexed)
                            Padding(
                              key: ValueKey('help-step-${topic.id}-$index'),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${index + 1}.',
                                      style: HelpCenterStyle.body.copyWith(
                                        color: HelpCenterStyle.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: HelpCenterStyle.body,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (topic.note != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            topic.note!,
                            key: ValueKey('help-note-${topic.id}'),
                            style: HelpCenterStyle.body,
                          ),
                        ],
                        if (onOpen != null && topic.actionLabel != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: ValueKey('help-open-${topic.id}'),
                              onPressed: onOpen,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(topic.actionLabel!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ),
  );
}
