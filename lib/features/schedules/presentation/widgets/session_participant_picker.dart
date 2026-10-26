import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../domain/entities/lesson.dart';
import 'session_detail_style.dart';

/// Reports remain individual even when the lesson is taught as a group.
Future<List<String>?> chooseReportSessions(
  BuildContext context,
  Lesson lesson, {
  Set<String> existingSessionIds = const {},
}) async {
  if (!lesson.isGroup) {
    return lesson.status == 'cancelled' ||
            existingSessionIds.contains(lesson.id)
        ? null
        : [lesson.id];
  }
  final participants = lesson.participants
      .where(
        (p) =>
            p.status != 'cancelled' &&
            !existingSessionIds.contains(p.sessionId),
      )
      .toList();
  if (participants.isEmpty) return null;
  Set<String> selected = {};
  return showModalBottomSheet<List<String>>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: SessionDetailStyle.cream,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Laporan untuk siswa',
                style: SessionDetailStyle.title,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih satu atau beberapa siswa. Isi laporan diterapkan ke siswa yang dicentang dan tetap disimpan terpisah.',
                style: SessionDetailStyle.body,
              ),
              const SizedBox(height: 16),
              NalaraMultiDropdown<String>(
                key: const ValueKey('report-session-student'),
                selectedValues: selected,
                hint: 'Pilih satu atau beberapa siswa',
                searchHint: 'Cari siswa...',
                menuTitle: 'Pilih siswa',
                options: participants
                    .map(
                      (p) => NalaraDropdownOption(
                        value: p.sessionId,
                        label: p.studentName,
                      ),
                    )
                    .toList(),
                onChanged: (value) => setSheetState(() => selected = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.of(sheetContext).pop(
                        participants
                            .where((p) => selected.contains(p.sessionId))
                            .map((p) => p.sessionId)
                            .toList(),
                      ),
                child: const Text('Tulis laporan'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String reportFormLocation(
  List<String> sessionIds, {
  String routePrefix = '/teacher',
}) => Uri(
  path: '$routePrefix/reports/new',
  queryParameters: {
    'sessionId': sessionIds.first,
    if (sessionIds.length > 1) 'sessionIds': sessionIds.join(','),
  },
).toString();
