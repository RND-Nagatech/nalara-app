import 'package:flutter/material.dart';

/// Branded load-more action shared by paginated list screens.
class NalaraLoadMoreButton extends StatelessWidget {
  final bool hasMore;
  final bool loading;
  final VoidCallback onPressed;
  final Key? buttonKey;
  final String label;

  const NalaraLoadMoreButton({
    super.key,
    required this.hasMore,
    required this.loading,
    required this.onPressed,
    this.buttonKey,
    this.label = 'Muat lebih banyak',
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();

    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return FilledButton.icon(
      key: buttonKey,
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: onPrimary,
              ),
            )
          : const Icon(Icons.expand_more_rounded),
      label: Text(label),
    );
  }
}
