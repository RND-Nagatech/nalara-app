import 'package:flutter/material.dart';

/// The tutorial sits beside the Router in MaterialApp.builder. Its controls
/// therefore need their own Overlay ancestor for tooltips and floating UI.
class TeachingTutorialLayer extends StatefulWidget {
  final Widget child;
  const TeachingTutorialLayer({super.key, required this.child});

  @override
  State<TeachingTutorialLayer> createState() => _TeachingTutorialLayerState();
}

class _TeachingTutorialLayerState extends State<TeachingTutorialLayer> {
  late final _entry = OverlayEntry(
    builder: (_) => Positioned.fill(child: widget.child),
  );

  @override
  void didUpdateWidget(TeachingTutorialLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Overlay.initialEntries is used only on creation. Keep the mounted entry
    // in sync with geometry, account and tutorial-state changes from the host.
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
