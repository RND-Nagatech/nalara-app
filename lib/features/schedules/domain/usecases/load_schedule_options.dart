import '../../../student_groups/domain/student_group.dart';
import '../../../student_groups/domain/student_groups_repository.dart';
import 'load_teaching_options.dart';

class LoadScheduleOptions {
  final LoadTeachingOptions teaching;
  final StudentGroupsRepository groups;
  LoadScheduleOptions(this.teaching, this.groups);
  Future<TeachingOptions> call() async {
    final options = await teaching();
    final items = <StudentGroup>[];
    var page = 1;
    while (true) {
      final result = await groups.list(page: page, limit: 100);
      items.addAll(result.items);
      if (!result.hasNext) break;
      page++;
    }
    return TeachingOptions(options.students, options.subjects, groups: items);
  }
}
