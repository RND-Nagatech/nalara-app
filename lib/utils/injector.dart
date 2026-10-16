import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../shared/network/api_client.dart';
import '../shared/domain/teaching_catalog_changes.dart';
import '../shared/network/token_store.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/restore_session.dart';
import '../features/auth/data/datasources/auth_remote_source.dart';
import '../features/auth/data/datasources/password_reset_local_source.dart';
import '../features/auth/data/datasources/remembered_login_local_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/services/google_auth_service.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/bloc/password_reset_cubit.dart';
import '../features/access/data/datasources/access_local_source.dart';
import '../features/access/data/datasources/installation_local_source.dart';
import '../features/access/data/datasources/access_remote_source.dart';
import '../features/access/data/repositories/access_repository_impl.dart';
import '../features/access/domain/repositories/access_repository.dart';
import '../features/families/data/datasources/families_remote_source.dart';
import '../features/families/data/repositories/families_repository_impl.dart';
import '../features/families/domain/repositories/families_repository.dart';
import '../features/families/domain/usecases/load_family_options.dart';
import '../features/families/domain/usecases/load_family_editor.dart';
import '../features/learning_goals/domain/usecases/update_progress.dart';
import '../features/learning_goals/domain/usecases/load_progress_form.dart';
import '../features/learning_goals/domain/usecases/load_plan_overview.dart';
import '../features/schedules/domain/usecases/load_teaching_options.dart';
import '../features/students/domain/repositories/students_repository.dart';
import '../features/students/domain/usecases/load_students.dart';
import '../features/students/domain/usecases/load_student_overview.dart';
import '../features/students/presentation/bloc/students_cubit.dart';
import '../features/students/data/datasources/students_remote_source.dart';
import '../features/students/data/repositories/students_repository_impl.dart';
import '../features/subjects/domain/repositories/subjects_repository.dart';
import '../features/subjects/data/datasources/subjects_remote_source.dart';
import '../features/subjects/data/repositories/subjects_repository_impl.dart';
import '../features/schedules/domain/repositories/schedules_repository.dart';
import '../features/schedules/domain/usecases/load_schedule_agenda.dart';
import '../features/schedules/domain/usecases/load_session_overview.dart';
import '../features/schedules/presentation/bloc/schedule_agenda_cubit.dart';
import '../features/schedules/data/datasources/schedules_remote_source.dart';
import '../features/schedules/data/repositories/schedules_repository_impl.dart';
import '../features/learning_goals/domain/repositories/learning_repository.dart';
import '../features/learning_goals/data/datasources/learning_remote_source.dart';
import '../features/learning_goals/data/repositories/learning_repository_impl.dart';
import '../features/progress_history/domain/repositories/history_repository.dart';
import '../features/progress_history/data/datasources/history_remote_source.dart';
import '../features/progress_history/data/repositories/history_repository_impl.dart';
import '../features/lesson_reports/domain/repositories/reports_repository.dart';
import '../features/lesson_reports/data/datasources/reports_remote_source.dart';
import '../features/lesson_reports/data/repositories/reports_repository_impl.dart';
import '../features/notifications/domain/repositories/notifications_repository.dart';
import '../features/notifications/data/datasources/notifications_remote_source.dart';
import '../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/data/datasources/dashboard_remote_source.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/usecases/load_teacher_home.dart';
import '../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../features/parent_portal/data/datasources/parent_portal_remote_source.dart';
import '../features/parent_portal/data/repositories/parent_portal_repository_impl.dart';
import '../features/parent_portal/domain/repositories/parent_portal_repository.dart';
import '../features/student_portal/data/datasources/student_portal_remote_source.dart';
import '../features/student_portal/data/repositories/student_portal_repository_impl.dart';
import '../features/student_portal/domain/repositories/student_portal_repository.dart';
import '../features/reschedule_requests/data/datasources/reschedule_requests_remote_source.dart';
import '../features/reschedule_requests/data/repositories/reschedule_requests_repository_impl.dart';
import '../features/reschedule_requests/domain/repositories/reschedule_requests_repository.dart';
import '../shared/notifications/push_notification_service.dart';
import 'constants.dart';
import '../features/subscription/data/subscription_repository_impl.dart';
import '../features/subscription/domain/subscription_repository.dart';
import '../features/subscription/presentation/subscription_cubit.dart';
import '../features/tutor_tools/data/tutor_tools_repository_impl.dart';
import '../features/tutor_tools/domain/tutor_tools.dart';
import '../features/tutor_tools/domain/load_tutor_catalog.dart';

final getIt = GetIt.instance;
Future<void> configureDependencies({bool checkInstallation = true}) async {
  getIt.registerLazySingleton(
    () => InstallationLocalSource(const FlutterSecureStorage()),
  );
  getIt.registerLazySingleton(() => TokenStore(const FlutterSecureStorage()));
  getIt.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          compact: true,
          maxWidth: 120,
          enabled: true,
          filter: (options, _) => ![
            '/auth/',
            '/invitations/',
            '/portal/',
          ].any(options.path.startsWith),
        ),
      );
    }
    return dio;
  }, dispose: (dio) => dio.close(force: true));
  getIt.registerLazySingleton(
    () => ApiClient(getIt<Dio>(), getIt<TokenStore>()),
  );
  getIt.registerLazySingleton(
    () => SubscriptionRemoteSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(getIt<SubscriptionRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => SubscriptionCubit(getIt<SubscriptionRepository>()),
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton(
    () => TutorToolsRemoteSource(
      getIt<ApiClient>(),
      getIt<ApiClient>(instanceName: 'portal'),
    ),
  );
  getIt.registerLazySingleton<TutorToolsRepository>(
    () => TutorToolsRepositoryImpl(getIt<TutorToolsRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => LoadTutorCatalog(
      getIt<StudentsRepository>(),
      getIt<SubjectsRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => TokenStore(const FlutterSecureStorage(), namespace: 'portal-'),
    instanceName: 'portal',
  );
  getIt.registerLazySingleton(
    () => ApiClient(
      getIt<Dio>(),
      getIt<TokenStore>(instanceName: 'portal'),
      refreshPath: ApiConstants.portalRefresh,
    ),
    instanceName: 'portal',
  );
  getIt.registerLazySingleton(
    () => PushNotificationService(
      teacherApi: getIt<ApiClient>(),
      portalApi: getIt<ApiClient>(instanceName: 'portal'),
    ),
    dispose: (service) => service.dispose(),
  );
  getIt.registerLazySingleton(
    () => AccessLocalSource(
      const FlutterSecureStorage(),
      installation: checkInstallation ? getIt<InstallationLocalSource>() : null,
    ),
  );
  getIt.registerLazySingleton(
    () => AccessRemoteSource(getIt<ApiClient>(instanceName: 'portal')),
  );
  getIt.registerLazySingleton(
    () => ParentPortalRemoteSource(getIt<ApiClient>(instanceName: 'portal')),
  );
  getIt.registerLazySingleton<ParentPortalRepository>(
    () => ParentPortalRepositoryImpl(getIt<ParentPortalRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => StudentPortalRemoteSource(getIt<ApiClient>(instanceName: 'portal')),
  );
  getIt.registerLazySingleton<StudentPortalRepository>(
    () => StudentPortalRepositoryImpl(getIt<StudentPortalRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => RescheduleRequestsRemoteSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<RescheduleRequestsRepository>(
    () => RescheduleRequestsRepositoryImpl(
      getIt<RescheduleRequestsRemoteSource>(),
    ),
  );
  getIt.registerLazySingleton<AccessRepository>(
    () => AccessRepositoryImpl(
      getIt<AccessRemoteSource>(),
      getIt<AccessLocalSource>(),
      getIt<TokenStore>(instanceName: 'portal'),
    ),
  );
  getIt.registerLazySingleton(() => AuthRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton(
    () => PasswordResetLocalSource(const FlutterSecureStorage()),
  );
  getIt.registerLazySingleton(
    () => RememberedLoginLocalSource(const FlutterSecureStorage()),
  );
  getIt.registerLazySingleton(() => GoogleAuthService());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteSource>(),
      getIt<TokenStore>(),
      googleAuth: getIt<GoogleAuthService>(),
      rememberedLogin: getIt<RememberedLoginLocalSource>(),
    ),
  );
  getIt.registerLazySingleton(
    () => RestoreSession(getIt<AuthRepository>(), getIt<AccessRepository>()),
  );
  getIt.registerLazySingleton(
    () => AuthCubit(
      getIt<AuthRepository>(),
      access: getIt<AccessRepository>(),
      push: getIt<PushNotificationService>(),
      restoreSession: getIt<RestoreSession>(),
    ),
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton(
    () => PasswordResetCubit(
      getIt<AuthRepository>(),
      getIt<PasswordResetLocalSource>(),
    ),
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton(() => StudentsRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<StudentsRepository>(
    () => StudentsRepositoryImpl(getIt<StudentsRemoteSource>()),
  );
  getIt.registerLazySingleton(() => LoadStudents(getIt<StudentsRepository>()));
  getIt.registerFactory(() => StudentsCubit(getIt<LoadStudents>()));
  getIt.registerLazySingleton(() => FamiliesRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<FamiliesRepository>(
    () => FamiliesRepositoryImpl(getIt<FamiliesRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => LoadFamilyStudents(getIt<StudentsRepository>()),
  );
  getIt.registerLazySingleton(() => LoadFamilies(getIt<FamiliesRepository>()));
  getIt.registerLazySingleton(
    () => LoadFamilyEditor(
      getIt<FamiliesRepository>(),
      getIt<LoadFamilyStudents>(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoadFamilyOverview(getIt<FamiliesRepository>()),
  );
  getIt.registerLazySingleton(() => SubjectsRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton(
    () => TeachingCatalogChanges(),
    dispose: (changes) => changes.close(),
  );
  getIt.registerLazySingleton<SubjectsRepository>(
    () => SubjectsRepositoryImpl(
      getIt<SubjectsRemoteSource>(),
      changes: getIt<TeachingCatalogChanges>(),
    ),
  );
  getIt.registerLazySingleton(() => SchedulesRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<SchedulesRepository>(
    () => SchedulesRepositoryImpl(getIt<SchedulesRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => LoadScheduleAgenda(getIt<SchedulesRepository>()),
  );
  getIt.registerFactory(() => ScheduleAgendaCubit(getIt<LoadScheduleAgenda>()));
  getIt.registerLazySingleton(() => LearningRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<LearningRepository>(
    () => LearningRepositoryImpl(getIt<LearningRemoteSource>()),
  );
  getIt.registerLazySingleton(() => HistoryRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(getIt<HistoryRemoteSource>()),
  );
  getIt.registerLazySingleton(() => ReportsRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(getIt<ReportsRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => LoadSessionOverview(
      getIt<SchedulesRepository>(),
      getIt<ReportsRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoadStudentOverview(
      getIt<StudentsRepository>(),
      getIt<LearningRepository>(),
      getIt<SchedulesRepository>(),
      getIt<ReportsRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => NotificationsRemoteSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(getIt<NotificationsRemoteSource>()),
  );
  getIt.registerLazySingleton(() => DashboardRemoteSource(getIt<ApiClient>()));
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt<DashboardRemoteSource>()),
  );
  getIt.registerLazySingleton(
    () => LoadTeacherHome(getIt<DashboardRepository>()),
  );
  getIt.registerFactory(() => DashboardCubit(getIt<LoadTeacherHome>()));
  getIt.registerLazySingleton(
    () => UpdateProgress(getIt<LearningRepository>()),
  );
  getIt.registerLazySingleton(() => PlanProgressLabel());
  getIt.registerLazySingleton(
    () => LoadPlanOverview(
      getIt<LearningRepository>(),
      getIt<StudentsRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoadProgressForm(
      getIt<LearningRepository>(),
      getIt<StudentsRepository>(),
      getIt<SchedulesRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoadTeachingOptions(
      getIt<StudentsRepository>(),
      getIt<SubjectsRepository>(),
    ),
  );
  getIt<ApiClient>().onExpired = getIt<AuthCubit>().expire;
  getIt<ApiClient>(instanceName: 'portal').onExpired =
      getIt<AuthCubit>().expirePortal;
}
