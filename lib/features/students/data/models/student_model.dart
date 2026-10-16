import '../../domain/entities/student.dart';
import '../../../access/data/models/referral_invitation_model.dart';

class StudentModel {
  final Map<String, dynamic> json;
  StudentModel(this.json);
  Student toEntity() => Student(
    id: json['_id'],
    name: json['name'],
    grade: json['grade'] ?? '',
    notes: json['notes'] ?? '',
    status: json['status'],
    familyId: json['familyId'],
    learningSummary: json['learningSummary'] == null
        ? null
        : _learningSummary(Map<String, dynamic>.from(json['learningSummary'])),
  );

  StudentLearningSummary _learningSummary(Map<String, dynamic> value) =>
      StudentLearningSummary(
        subjectNames: List<String>.from(value['subjectNames']),
        weeklyProgress: value['weeklyProgress'] as int?,
        targetCount: value['targetCount'] as int,
        weekStartDate: value['weekStartDate'] as String,
        weekEndDate: value['weekEndDate'] as String,
        timezone: value['timezone'] as String,
      );
}

class InvitationModel {
  final Map<String, dynamic> json;
  InvitationModel(this.json);
  ParentInvitation toEntity() => ReferralInvitationModel(json).toEntity();
}
