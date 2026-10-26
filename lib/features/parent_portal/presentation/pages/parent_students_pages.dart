import 'package:flutter/material.dart';
import '../../../../utils/injector.dart';
import '../../../students/domain/usecases/load_students.dart';
import '../../../students/presentation/pages/students_list_page.dart';
import '../../../students/presentation/pages/student_detail_page.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../../domain/usecases/load_parent_student_overview.dart';
import '../../../tuition_fees/domain/tuition_repository.dart';

class ParentSharedStudentsPage extends StatelessWidget {
  const ParentSharedStudentsPage({super.key});
  @override
  Widget build(BuildContext context) => StudentsPage(
    loader: LoadStudents.fromReader(getIt<ParentPortalRepository>().students),
    readOnly: true,
    routePrefix: '/parent',
  );
}

class ParentSharedStudentDetailPage extends StatelessWidget {
  final String id;
  final String? initialTab;
  const ParentSharedStudentDetailPage({
    super.key,
    required this.id,
    this.initialTab,
  });
  @override
  Widget build(BuildContext context) => StudentDetailPage(
    id: id,
    loader: LoadParentStudentOverview(getIt<ParentPortalRepository>()),
    readOnly: true,
    routePrefix: '/parent',
    initialTab: initialTab,
    tuitionReader: getIt<TuitionReader>(instanceName: 'parent'),
  );
}
