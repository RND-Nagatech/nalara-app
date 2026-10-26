import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../domain/entities/lesson.dart';
import 'session_detail_style.dart';

class GroupAttendanceCard extends StatefulWidget {
  final List<SessionParticipant> participants;
  final bool busy;
  final String? unavailableReason;
  final ValueChanged<List<AttendanceSelection>>? onSave;
  final ValueChanged<SessionParticipant>? onStudent;
  const GroupAttendanceCard({
    super.key,
    required this.participants,
    required this.busy,
    required this.onSave,
    this.unavailableReason,
    this.onStudent,
  });

  @override
  State<GroupAttendanceCard> createState() => _GroupAttendanceCardState();
}

class _GroupAttendanceCardState extends State<GroupAttendanceCard> {
  final _choices = <String, String>{};
  bool get _enabled => !widget.busy && widget.onSave != null;

  @override
  void didUpdateWidget(covariant GroupAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _choices.removeWhere(
      (id, _) =>
          !widget.participants.any((p) => p.sessionId == id && p.editable),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.participants.where((p) => p.editable).toList();
    final recorded = widget.participants.length - pending.length;
    return SessionSectionCard(
      title: 'Presensi kelompok',
      description:
          widget.unavailableReason ??
          '$recorded dari ${widget.participants.length} siswa sudah tercatat. Pilih status, lalu simpan sekaligus. Presensi tersimpan tidak dapat diubah.',
      children: [
        if (pending.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('group-all-present'),
              onPressed: !_enabled
                  ? null
                  : () => setState(() {
                      for (final p in pending) {
                        _choices[p.sessionId] = 'present';
                      }
                    }),
              child: const Text('Tandai semua hadir'),
            ),
          ),
        for (final p in widget.participants)
          Padding(
            key: ValueKey('group-attendance-${p.sessionId}'),
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: widget.busy || widget.onStudent == null
                      ? null
                      : () => widget.onStudent!(p),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    p.studentName,
                    style: SessionDetailStyle.title.copyWith(fontSize: 14),
                  ),
                ),
                if (!p.editable)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SessionStatusBadge(
                      label: '${statusLabel(p.attendance)} · Terkunci',
                      background: SessionDetailStyle.sage,
                      foreground: SessionDetailStyle.green,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final option in const {
                        'present': 'Hadir',
                        'excused': 'Izin',
                        'absent': 'Alpa',
                      }.entries)
                        ChoiceChip(
                          key: ValueKey('group-${p.sessionId}-${option.key}'),
                          label: Text(option.value),
                          selected: _choices[p.sessionId] == option.key,
                          selectedColor: SessionDetailStyle.sage,
                          onSelected: !_enabled
                              ? null
                              : (selected) => setState(() {
                                  if (selected) {
                                    _choices[p.sessionId] = option.key;
                                  } else {
                                    _choices.remove(p.sessionId);
                                  }
                                }),
                        ),
                    ],
                  ),
                if (p.status == 'cancelled') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Alasan pembatalan: ${p.cancellationReason ?? 'Belum dicatat.'}',
                    style: SessionDetailStyle.body,
                  ),
                ],
              ],
            ),
          ),
        if (pending.isNotEmpty) ...[
          Text(
            '${_choices.length} dipilih · ${pending.length - _choices.length} belum dipilih',
            style: SessionDetailStyle.body,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('group-save-attendance'),
            onPressed: !_enabled || _choices.isEmpty
                ? null
                : () => widget.onSave!(
                    List.unmodifiable(
                      _choices.entries.map(
                        (e) => AttendanceSelection(e.key, e.value),
                      ),
                    ),
                  ),
            child: widget.busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Simpan ${_choices.length} presensi'),
          ),
        ],
      ],
    );
  }
}
