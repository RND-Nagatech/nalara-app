import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/color.dart';

/// Feature pages retain their date ranges and timezone conversions; the dialog
/// uses the same visual theme even when opened from a locally themed form.
Future<DateTime?> showNalaraDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String helpText = 'Pilih tanggal',
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: helpText,
  cancelText: 'Batal',
  confirmText: 'Pilih tanggal',
  barrierColor: NalaraColors.scrim,
  builder: _pickerBuilder,
);

Future<TimeOfDay?> showNalaraTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  initialEntryMode: TimePickerEntryMode.inputOnly,
  helpText: 'Pilih waktu',
  hourLabelText: 'Jam',
  minuteLabelText: 'Menit',
  cancelText: 'Batal',
  confirmText: 'Simpan waktu',
  barrierColor: NalaraColors.scrim,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
    child: _pickerBuilder(context, child),
  ),
);

Widget _pickerBuilder(BuildContext context, Widget? child) => Theme(
  data: buildAppTheme().copyWith(platform: Theme.of(context).platform),
  child: child ?? const SizedBox.shrink(),
);
