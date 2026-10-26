import 'package:flutter/material.dart';
import '../../../../shared/domain/app_timezones.dart';
import 'agenda_style.dart';

class AgendaHeader extends StatelessWidget {
  final bool loading;
  final VoidCallback onRefresh;
  final bool attendance;
  final bool readOnly;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? subtitle, timezone;
  const AgendaHeader({
    super.key,
    required this.loading,
    required this.onRefresh,
    this.attendance = false,
    this.readOnly = false,
    this.onBack,
    this.actions = const [],
    this.subtitle,
    this.timezone,
  });
  @override
  Widget build(BuildContext context) => attendance
      ? Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('attendance-back'),
                    tooltip: 'Kembali',
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      foregroundColor: AgendaStyle.green,
                      minimumSize: const Size(44, 44),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Presensi',
                      style: TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 20,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: AgendaStyle.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _refresh(),
                  ...actions,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                subtitle ??
                    (readOnly
                        ? 'Pantau kehadiran anak di setiap sesi belajar.'
                        : 'Pantau kehadiran siswa di setiap sesi belajar.'),
                style: AgendaStyle.body,
              ),
              if (timezone != null) _zone(),
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jadwal les', style: AgendaStyle.title),
                    const SizedBox(height: 5),
                    Text(
                      subtitle ??
                          (readOnly
                              ? 'Jadwal seluruh anak yang terhubung'
                              : 'Atur dan kelola sesi les Anda'),
                      style: AgendaStyle.body,
                    ),
                    if (timezone != null) _zone(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _refresh(),
              ...actions,
            ],
          ),
        );

  Widget _zone() => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text(
      'Waktu ${AppTimezones.abbreviation(timezone!)}',
      style: AgendaStyle.body.copyWith(fontSize: 11),
    ),
  );

  Widget _refresh() => IconButton(
    key: ValueKey(attendance ? 'attendance-refresh' : 'agenda-refresh'),
    tooltip: attendance ? 'Muat ulang presensi' : 'Muat ulang jadwal',
    onPressed: loading ? null : onRefresh,
    style: IconButton.styleFrom(
      foregroundColor: AgendaStyle.green,
      fixedSize: const Size(40, 40),
    ),
    icon: loading
        ? const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AgendaStyle.green,
            ),
          )
        : const Icon(Icons.refresh_rounded, size: 24),
  );
}
