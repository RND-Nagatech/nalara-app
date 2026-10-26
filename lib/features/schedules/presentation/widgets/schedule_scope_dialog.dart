import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_dialog.dart';
import 'schedule_form_style.dart';

Future<bool?> chooseCancellationScope(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => NalaraDialog(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Batalkan pertemuan mana?', style: ScheduleFormStyle.label),
        const SizedBox(height: 10),
        const Text(
          'Pertemuan yang sudah selesai tetap tersimpan. Untuk jadwal kelompok, pilihan berlaku bagi seluruh peserta.',
          style: ScheduleFormStyle.supporting,
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Pertemuan ini saja'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Pertemuan ini dan berikutnya',
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali'),
        ),
      ],
    ),
  ),
);
