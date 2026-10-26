class TuitionFee {
  final String id, studentId, dueDate, status;
  final int amount, version;
  const TuitionFee({
    required this.id,
    required this.studentId,
    required this.dueDate,
    required this.status,
    required this.amount,
    required this.version,
  });
  bool get paid => status == 'paid';
}

class TuitionOverview {
  final TuitionFee? fee;
  final String teacherName, timezone;
  final String? teacherPhone;
  final bool automaticReminders;
  final bool tuitionTeacherReminders, tuitionParentReminders;
  const TuitionOverview({
    required this.fee,
    required this.teacherName,
    required this.teacherPhone,
    required this.timezone,
    required this.automaticReminders,
    this.tuitionTeacherReminders = true,
    this.tuitionParentReminders = true,
  });
}

Uri? tuitionContactUri(String? phone, String studentName, DateTime localNow) {
  if (phone == null) return null;
  var number = phone.replaceAll(RegExp(r'[\s()+-]'), '');
  if (number.startsWith('0')) number = '62${number.substring(1)}';
  if (!RegExp(r'^628[1-9]\d{7,10}$').hasMatch(number)) return null;
  final greeting = localNow.hour < 11
      ? 'pagi'
      : localNow.hour < 15
      ? 'siang'
      : localNow.hour < 18
      ? 'sore'
      : 'malam';
  final message =
      'Halo, selamat $greeting. Saya orang tua dari $studentName ingin mengonfirmasi tentang pembayaran bimbelnya. Terima kasih.';
  return Uri.https('wa.me', '/$number', {'text': message});
}
