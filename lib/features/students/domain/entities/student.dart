import '../../../access/domain/entities/referral_invitation.dart';

class Student {
  final String id, name, grade, notes, status;
  final String? familyId;
  final StudentLearningSummary? learningSummary;
  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.notes,
    required this.status,
    this.familyId,
    this.learningSummary,
  });
}

class StudentLearningSummary {
  final List<String> subjectNames;
  final int? weeklyProgress;
  final int targetCount;
  final String weekStartDate, weekEndDate, timezone;

  StudentLearningSummary({
    required List<String> subjectNames,
    required this.weeklyProgress,
    required this.targetCount,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.timezone,
  }) : subjectNames = List.unmodifiable(subjectNames);
}

class StudentDraft {
  final String name, grade, notes;
  final String? familyId;
  final bool clearFamily;
  const StudentDraft({
    required this.name,
    this.grade = '',
    this.notes = '',
    this.familyId,
    this.clearFamily = false,
  });
}

// Kept as a source-compatible name for the existing teacher feature.
typedef ParentInvitation = ReferralInvitation;
