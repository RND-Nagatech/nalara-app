import 'package:flutter/material.dart';
import '../../../utils/color.dart';

class NotificationPreferenceTile extends StatelessWidget {
  final String title, description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const NotificationPreferenceTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    enabled: onChanged != null,
    button: true,
    label: title,
    child: InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: NalaraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ExcludeSemantics(
              child: Opacity(
                opacity: onChanged == null ? 0.5 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 26,
                  padding: const EdgeInsets.all(3),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: value ? NalaraColors.green : NalaraColors.line,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
