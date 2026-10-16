import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/color.dart';

enum NalaraNoticeType { success, error, info, warning }

/// Displays a themed, non-native notification above the current page.
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
      title: title ?? _defaultTitle(type),
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
  final String title;
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
    final colors = _noticeColors(widget.type);
    final media = MediaQuery.of(context);
    return Positioned(
      left: 18,
      right: 18,
      top: media.padding.top + 12,
      child: IgnorePointer(
        ignoring: !_visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, -0.35),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: _visible ? 1 : 0,
            child: Semantics(
              liveRegion: true,
              container: true,
              label: '${widget.title}. ${widget.message}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A214E3B),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.iconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          colors.icon,
                          color: colors.iconColor,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: NalaraColors.ink,
                                  fontFamily: 'NalaraInter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  color: NalaraColors.muted,
                                  fontFamily: 'NalaraInter',
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _dismiss,
                        icon: const Icon(Icons.close_rounded, size: 19),
                        color: NalaraColors.muted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        splashRadius: 18,
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
    );
  }
}

({
  Color background,
  Color border,
  Color iconBackground,
  Color iconColor,
  IconData icon,
})
_noticeColors(NalaraNoticeType type) => switch (type) {
  NalaraNoticeType.success => (
    background: const Color(0xFFF0F7F0),
    border: const Color(0xFFB8D4BE),
    iconBackground: NalaraColors.lightGreen,
    iconColor: NalaraColors.green,
    icon: Icons.check_rounded,
  ),
  NalaraNoticeType.error => (
    background: const Color(0xFFFFF4F1),
    border: const Color(0xFFE6B8AD),
    iconBackground: const Color(0xFFF8DCD5),
    iconColor: const Color(0xFFA64235),
    icon: Icons.priority_high_rounded,
  ),
  NalaraNoticeType.info => (
    background: const Color(0xFFF0F5F7),
    border: const Color(0xFFB7CED4),
    iconBackground: const Color(0xFFD9EAF0),
    iconColor: const Color(0xFF356C78),
    icon: Icons.info_outline_rounded,
  ),
  NalaraNoticeType.warning => (
    background: const Color(0xFFFFF8EA),
    border: const Color(0xFFE8D1A2),
    iconBackground: const Color(0xFFF7E8C5),
    iconColor: const Color(0xFF8B681D),
    icon: Icons.warning_amber_rounded,
  ),
};
