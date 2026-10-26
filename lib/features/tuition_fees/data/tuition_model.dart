import '../domain/tuition_fee.dart';

class TuitionModel {
  final Map<String, dynamic> json;
  TuitionModel(this.json);
  TuitionOverview toEntity() {
    final fee = json['fee'] as Map?;
    final teacher = json['teacher'] as Map;
    return TuitionOverview(
      fee: fee == null
          ? null
          : TuitionFee(
              id: fee['_id'] as String,
              studentId: fee['studentId'] as String,
              amount: fee['amount'] as int,
              dueDate: fee['dueDate'] as String,
              status: fee['status'] as String,
              version: fee['version'] as int,
            ),
      teacherName: teacher['name'] as String,
      teacherPhone: teacher['phone'] as String?,
      timezone: teacher['timezone'] as String,
      automaticReminders: json['automaticReminders'] as bool,
      tuitionTeacherReminders: json['tuitionTeacherReminders'] != false,
      tuitionParentReminders: json['tuitionParentReminders'] != false,
    );
  }
}
