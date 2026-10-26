import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/color.dart';

enum NalaraNoticeType { success, error, info, warning }

/// Displays a compact, neutral toast above the current page.
/// An explicit title adds a heading; otherwise the message stands on its own.
///
/// The returned future completes after the notice has finished its visible
/// duration. This makes it possible to wait for a success message before
/// navigating to another page.
Future<void> showNalaraNotice(
  BuildContext context,
  String message, {
  NalaraNoticeType type = NalaraNoticeType.success,
  String? title,
  Duration duration = const Duration(milliseconds: 1800),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future<void>.value();

  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _NalaraNoticeOverlay(
      message: message,
      title: title,
      type: type,
      duration: duration,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

String _defaultTitle(NalaraNoticeType type) => switch (type) {
  NalaraNoticeType.success => 'Berhasil',
  NalaraNoticeType.error => 'Terjadi kendala',
  NalaraNoticeType.info => 'Informasi',
  NalaraNoticeType.warning => 'Perhatian',
};

class _NalaraNoticeOverlay extends StatefulWidget {
  final String? title;
  final String message;
  final NalaraNoticeType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _NalaraNoticeOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_NalaraNoticeOverlay> createState() => _NalaraNoticeOverlayState();
}

class _NalaraNoticeOverlayState extends State<_NalaraNoticeOverlay> {
  Timer? _dismissTimer;
  Timer? _removeTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      _dismissTimer = Timer(widget.duration, _dismiss);
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
    _removeTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = _noticeStyle(widget.type);
    final media = MediaQuery.of(context);
    final title = widget.title?.trim();
    final hasTitle = title != null && title.isNotEmpty;
    final top = media.padding.top + 12;
    final availableHeight = math.max(
      0.0,
      media.size.height -
          top -
          media.viewInsets.bottom -
          media.padding.bottom -
          16,
    );
    return Positioned(
      left: media.padding.left + 16,
      right: media.padding.right + 16,
      top: top,
      child: IgnorePointer(
        ignoring: !_visible,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            duration: media.disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            offset: _visible ? Offset.zero : const Offset(0, -0.12),
            child: AnimatedOpacity(
              duration: media.disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              opacity: _visible ? 1 : 0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 440,
                  maxHeight: availableHeight,
                ),
                decoration: BoxDecoration(
                  color: NalaraColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NalaraColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: NalaraColors.ink.withValues(alpha: .08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Semantics(
                    liveRegion: true,
                    container: true,
                    label:
                        '${hasTitle ? title : _defaultTitle(widget.type)}. ${widget.message}',
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        14,
                        6,
                        4,
                        6,
                      ),
                      child: Row(
                        crossAxisAlignment: hasTitle
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Padding(
                              padding: hasTitle
                                  ? const EdgeInsets.only(top: 12)
                                  : EdgeInsets.zero,
                              child: Icon(
                                style.icon,
                                color: style.accent,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ExcludeSemantics(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasTitle) ...[
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: NalaraColors.ink,
                                          fontFamily: 'NalaraInter',
                                          fontSize: 13.5,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        color: hasTitle
                                            ? NalaraColors.muted
                                            : NalaraColors.ink,
                                        fontFamily: 'NalaraInter',
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _dismiss,
                            icon: const Icon(Icons.close_rounded, size: 17),
                            style: IconButton.styleFrom(
                              foregroundColor: NalaraColors.muted,
                              minimumSize: const Size.square(44),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.padded,
                              visualDensity: VisualDensity.standard,
                            ),
                            tooltip: 'Tutup notifikasi',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({Color accent, IconData icon}) _noticeStyle(NalaraNoticeType type) =>
    switch (type) {
      NalaraNoticeType.success => (
        accent: NalaraColors.green,
        icon: Icons.check_circle_outline_rounded,
      ),
      NalaraNoticeType.error => (
        accent: NalaraColors.danger,
        icon: Icons.error_outline_rounded,
      ),
      NalaraNoticeType.info => (
        accent: NalaraColors.muted,
        icon: Icons.info_outline_rounded,
      ),
      NalaraNoticeType.warning => (
        accent: NalaraColors.warning,
        icon: Icons.warning_amber_rounded,
      ),
    };
