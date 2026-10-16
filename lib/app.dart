import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'utils/app_theme.dart';
import 'utils/injector.dart';
import 'shared/widgets/teacher_bottom_navigation.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/password_reset_cubit.dart';
import 'features/auth/presentation/pages/auth_pages.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/access/domain/entities/app_role.dart';
import 'features/access/presentation/pages/role_selection_page.dart';
import 'features/access/presentation/pages/referral_page.dart';
import 'features/families/presentation/pages/families_pages.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/dashboard/presentation/widgets/home_style.dart';
import 'features/students/presentation/pages/students_pages.dart';
import 'features/subjects/presentation/pages/subjects_pages.dart';
import 'features/schedules/presentation/pages/schedules_pages.dart';
import 'features/learning_goals/presentation/pages/learning_pages.dart';
import 'features/progress_history/presentation/pages/history_page.dart';
import 'features/lesson_reports/presentation/pages/reports_pages.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/profile/presentation/pages/more_pages.dart';
import 'features/parent_portal/presentation/pages/parent_pages.dart';
import 'features/parent_portal/presentation/pages/parent_dashboard_page.dart';
import 'features/parent_portal/presentation/pages/parent_students_pages.dart';
import 'features/parent_portal/presentation/pages/parent_learning_pages.dart';
import 'features/parent_portal/presentation/pages/parent_report_pages.dart';
import 'features/parent_portal/presentation/pages/parent_shared_pages.dart';
import 'features/parent_portal/presentation/pages/parent_schedule_page.dart';
import 'features/parent_portal/presentation/pages/parent_shared_session_detail_page.dart';
import 'features/parent_portal/presentation/pages/parent_reschedule_requests_page.dart';
import 'features/parent_portal/domain/repositories/parent_portal_repository.dart';
import 'features/student_portal/presentation/pages/student_pages.dart';
import 'features/reschedule_requests/presentation/pages/reschedule_requests_page.dart';
import 'shared/notifications/push_notification_service.dart';
import 'features/subscription/presentation/subscription_cubit.dart';
import 'features/subscription/presentation/subscription_page.dart';
import 'features/tutor_tools/domain/tutor_tools.dart';
import 'features/tutor_tools/presentation/tutor_tools_pages.dart';
import 'shared/network/api_client.dart';

DateTime? _scheduleDate(String? value) {
  if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.year < 2020 || parsed.year > 2100) return null;
  final parts = value.split('-').map(int.parse).toList();
  return parsed.month == parts[1] && parsed.day == parts[2] ? parsed : null;
}

String _scheduleTimezone(String? candidate, String teacherTimezone) =>
    candidate == teacherTimezone ? candidate! : teacherTimezone;

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AuthRouterRefresh extends ChangeNotifier {
  late final StreamSubscription<AuthState> subscription;
  StreamSubscription<PasswordResetState>? resetSubscription;
  StreamSubscription<SubscriptionState>? subscriptionListener;
  AuthRouterRefresh(
    AuthCubit cubit, [
    PasswordResetCubit? reset,
    SubscriptionCubit? subscription,
  ]) {
    this.subscription = cubit.stream.listen((_) => notifyListeners());
    if (reset != null) {
      resetSubscription = reset.stream.listen((_) => notifyListeners());
    }
    subscriptionListener = subscription?.stream.listen(
      (_) => notifyListeners(),
    );
  }
  @override
  void dispose() {
    subscription.cancel();
    resetSubscription?.cancel();
    subscriptionListener?.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(
  AuthCubit auth,
  Listenable refresh, [
  PasswordResetCubit? reset,
  SubscriptionCubit? subscription,
]) {
  String? pendingRoute;
  String entry(AuthState state) {
    if (reset?.hasPendingFlow ?? false) return '/forgot-password';
    if (!state.onboardingSeen) return '/splash';
    return switch (state.selectedRole) {
      AppRole.teacher => '/login',
      AppRole.student => '/student/referral',
      AppRole.parent => '/parent/referral',
      null => '/roles',
    };
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, route) {
      final path = route.uri.path;
      final state = auth.state;
      final publicLegal = path.startsWith('/legal/');
      if ([
        AuthStatus.initial,
        AuthStatus.restoring,
        AuthStatus.failure,
      ].contains(state.status)) {
        if (reset?.hasPendingFlow ?? false) {
          return path == '/forgot-password' ? null : '/forgot-password';
        }
        if (publicLegal) return null;
        if (path.startsWith('/teacher/')) pendingRoute = route.uri.toString();
        return path == '/splash' ? null : '/splash';
      }
      final authenticated = state.status == AuthStatus.authenticated;
      if (authenticated && subscription != null && !publicLegal) {
        final checking =
            subscription.accountId != state.teacher?.id ||
            subscription.state.value == null;
        if (checking && path != '/teacher/subscription') {
          if (path.startsWith('/teacher/') &&
              !path.startsWith('/teacher/subscription')) {
            pendingRoute = route.uri.toString();
          }
          return '/teacher/subscription?entry=1';
        }
        if (!checking &&
            subscription.state.blocked &&
            ![
              '/teacher/subscription',
              '/teacher/subscription/students',
              '/teacher/profile',
              '/teacher/help',
            ].contains(path)) {
          return '/teacher/subscription';
        }
        if (!checking &&
            subscription.state.paywallFeature != null &&
            ![
              '/teacher/subscription',
              '/teacher/subscription/students',
              '/teacher/profile',
              '/teacher/help',
            ].contains(path)) {
          return '/teacher/subscription';
        }
        if (!checking &&
            !subscription.state.blocked &&
            path == '/teacher/subscription' &&
            route.uri.queryParameters['entry'] == '1') {
          final next = pendingRoute ?? '/teacher/home';
          pendingRoute = null;
          return next;
        }
      }
      final portalAuthenticated =
          state.status == AuthStatus.portalAuthenticated;
      final referral =
          path == '/student/referral' || path == '/parent/referral';
      if (publicLegal) return null;
      if (portalAuthenticated) {
        if (state.accessProfile?.role == AppRole.parent) {
          return path.startsWith('/parent/') ? null : '/parent/home';
        }
        return path.startsWith('/student/') ? null : '/student/home';
      }
      if (authenticated && path.startsWith('/parent/')) return '/teacher/home';
      if (authenticated && path.startsWith('/student/')) return '/teacher/home';
      if (!authenticated && path.startsWith('/teacher/')) {
        pendingRoute = route.uri.toString();
        return entry(state);
      }
      if (!authenticated &&
          (path.startsWith('/parent/') || path.startsWith('/student/'))) {
        pendingRoute = route.uri.toString();
        return entry(state);
      }
      if (authenticated &&
          [
            '/splash',
            '/login',
            '/register',
            '/onboarding',
            '/forgot-password',
            '/roles',
            '/student/referral',
            '/parent/referral',
          ].contains(path)) {
        final next = pendingRoute ?? '/teacher/home';
        pendingRoute = null;
        return next;
      }
      if (!authenticated && path == '/splash') {
        return state.onboardingSeen ? entry(state) : null;
      }
      if (!authenticated && !state.onboardingSeen && path != '/onboarding') {
        return '/splash';
      }
      if (!authenticated && referral && path != entry(state)) {
        return entry(state);
      }
      if (!authenticated &&
          ['/login', '/register', '/forgot-password'].contains(path) &&
          state.selectedRole != AppRole.teacher) {
        return entry(state);
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: TextButton(
          onPressed: () => context.go(
            auth.state.status == AuthStatus.authenticated
                ? '/teacher/home'
                : auth.state.status == AuthStatus.portalAuthenticated &&
                      auth.state.accessProfile?.role == AppRole.parent
                ? '/parent/home'
                : auth.state.status == AuthStatus.portalAuthenticated
                ? '/student/home'
                : entry(auth.state),
          ),
          child: const Text('Kembali ke beranda'),
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/roles', builder: (_, _) => const RoleSelectionPage()),
      GoRoute(
        path: '/student/referral',
        builder: (_, _) => const ReferralPage(role: AppRole.student),
      ),
      GoRoute(
        path: '/parent/referral',
        builder: (_, _) => const ReferralPage(role: AppRole.parent),
      ),
      GoRoute(path: '/login', builder: (_, _) => const AuthFormPage()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const AuthFormPage(register: true),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/legal/syarat-dan-ketentuan',
        builder: (_, _) =>
            const LegalDocumentPage(kind: LegalDocumentKind.terms),
      ),
      GoRoute(
        path: '/legal/kebijakan-privasi',
        builder: (_, _) =>
            const LegalDocumentPage(kind: LegalDocumentKind.privacy),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => TeacherShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/home',
                builder: (_, _) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/students',
                builder: (_, _) => const StudentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/schedule',
                builder: (_, state) => SchedulesPage(
                  initialDate: _scheduleDate(state.uri.queryParameters['date']),
                  initialPeriod:
                      const {
                        'day',
                        'week',
                        'month',
                      }.contains(state.uri.queryParameters['period'])
                      ? state.uri.queryParameters['period']!
                      : 'day',
                  timezone: _scheduleTimezone(
                    state.uri.queryParameters['timezone'],
                    auth.state.teacher?.timezone ?? 'Asia/Jakarta',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/targets',
                builder: (_, _) => const LearningPlansPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/more',
                builder: (_, _) => const MorePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ParentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/home',
                builder: (_, _) => const ParentDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/students',
                builder: (_, _) => const ParentSharedStudentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/schedule',
                builder: (_, state) => ParentSharedSchedulePage(
                  initialDate: _scheduleDate(state.uri.queryParameters['date']),
                  initialPeriod: state.uri.queryParameters['period'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/targets',
                builder: (_, state) => ParentLearningPlansPage(
                  studentId: state.uri.queryParameters['studentId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/more',
                builder: (_, _) => const ParentSharedMorePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StudentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/home',
                builder: (_, _) => const StudentHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/schedule',
                builder: (_, state) => StudentSchedulePage(
                  initialDate: DateTime.tryParse(
                    state.uri.queryParameters['date'] ?? '',
                  ),
                  initialPeriod: state.uri.queryParameters['period'] ?? 'day',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/targets',
                builder: (_, _) => const StudentTargetsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/reports',
                builder: (_, _) => const StudentReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/more',
                builder: (_, _) => const StudentMorePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/students/new',
        builder: (_, _) => const StudentFormPage(),
      ),
      GoRoute(
        path: '/teacher/students/:studentId',
        builder: (_, state) =>
            StudentDetailPage(id: state.pathParameters['studentId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                StudentFormPage(id: state.pathParameters['studentId']!),
          ),
          GoRoute(
            path: 'progress',
            builder: (_, state) => LearningPlansPage(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/schedule/new',
        builder: (_, state) =>
            ScheduleFormPage(studentId: state.uri.queryParameters['studentId']),
      ),
      GoRoute(
        path: '/teacher/schedule/:scheduleId',
        builder: (_, state) =>
            ScheduleDetailPage(id: state.pathParameters['scheduleId']!),
        routes: [
          GoRoute(
            path: 'sessions',
            builder: (_, state) =>
                SeriesSessionsPage(id: state.pathParameters['scheduleId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/sessions/:sessionId',
        builder: (_, state) =>
            SessionDetailPage(id: state.pathParameters['sessionId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                ReschedulePage(id: state.pathParameters['sessionId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/targets/new',
        builder: (_, state) => PlanFormPage(
          studentId: state.uri.queryParameters['studentId'],
          sourceTargetId: state.uri.queryParameters['sourceTargetId'],
        ),
      ),
      GoRoute(
        path: '/teacher/targets/:targetId',
        builder: (_, state) =>
            TargetDetailPage(id: state.pathParameters['targetId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                TargetFormPage(targetId: state.pathParameters['targetId']!),
          ),
          GoRoute(
            path: 'update-progress',
            builder: (_, state) =>
                UpdateProgressPage(id: state.pathParameters['targetId']!),
          ),
          GoRoute(
            path: 'history',
            builder: (_, state) =>
                HistoryPage(targetId: state.pathParameters['targetId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/plans/:planId',
        builder: (_, state) =>
            PlanDetailPage(id: state.pathParameters['planId']!),
        routes: [
          GoRoute(
            path: 'targets/new',
            builder: (_, state) =>
                TargetFormPage(planId: state.pathParameters['planId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/families',
        builder: (_, _) => const FamiliesPage(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const FamilyFormPage()),
          GoRoute(
            path: ':familyId',
            builder: (_, state) =>
                FamilyDetailPage(id: state.pathParameters['familyId']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) =>
                    FamilyFormPage(id: state.pathParameters['familyId']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/subjects',
        builder: (_, _) => const SubjectsPage(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const SubjectFormPage()),
          GoRoute(
            path: ':subjectId/edit',
            builder: (_, state) =>
                SubjectFormPage(id: state.pathParameters['subjectId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/reports',
        builder: (_, state) =>
            ReportsPage(studentId: state.uri.queryParameters['studentId']),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, state) => ReportFormPage(
              sessionId: state.uri.queryParameters['sessionId'],
            ),
          ),
          GoRoute(
            path: ':reportId',
            builder: (_, state) =>
                ReportDetailPage(id: state.pathParameters['reportId']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) =>
                    ReportFormPage(reportId: state.pathParameters['reportId']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/teacher/attendance',
        builder: (_, _) => const SchedulesPage(attendance: true),
      ),
      GoRoute(path: '/teacher/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/teacher/settings',
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(path: '/teacher/help', builder: (_, _) => const HelpPage()),
      GoRoute(
        path: '/teacher/materials',
        builder: (_, _) => const ActivitiesPage(),
      ),
      GoRoute(
        path: '/teacher/materials/new',
        builder: (_, state) => ActivityFormPage(
          activity: state.extra is LearningActivity
              ? state.extra as LearningActivity
              : null,
        ),
      ),
      GoRoute(
        path: '/teacher/assignments/:id',
        builder: (_, state) => ProToolsGate(
          feature: 'assignments',
          child: ActivityDetailPage(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/teacher/submissions/:id/feedback',
        builder: (_, state) => ProToolsGate(
          feature: 'assignments',
          child: FeedbackPage(
            submission: state.extra is ActivitySubmission
                ? state.extra as ActivitySubmission
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '/teacher/subscription',
        builder: (_, _) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/teacher/subscription/students',
        builder: (_, _) => const SubscriptionStudentsPage(),
      ),
      GoRoute(
        path: '/teacher/analytics',
        builder: (_, state) => ProgressAnalyticsPage(
          studentId: state.uri.queryParameters['studentId'],
        ),
      ),
      GoRoute(
        path: '/teacher/templates',
        builder: (_, state) =>
            TemplatesPage(select: state.uri.queryParameters['select'] == '1'),
      ),
      GoRoute(
        path: '/teacher/templates/new',
        builder: (_, state) => TemplateEditorPage(
          template: state.extra is ReportTemplate
              ? state.extra as ReportTemplate
              : null,
        ),
      ),
      GoRoute(
        path: '/teacher/branding',
        builder: (_, _) => const TutorPreferencesPage(branding: true),
      ),
      GoRoute(
        path: '/teacher/notification-preferences',
        builder: (_, _) => const TutorPreferencesPage(),
      ),
      GoRoute(
        path: '/teacher/export',
        builder: (_, _) => const DataExportPage(),
      ),
      GoRoute(
        path: '/teacher/reschedule-requests',
        builder: (_, _) => const RescheduleRequestsPage(),
      ),
      GoRoute(
        path: '/parent/students/:studentId',
        builder: (_, state) => ParentSharedStudentDetailPage(
          id: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: '/parent/sessions/:sessionId',
        builder: (_, state) => ParentSharedSessionDetailPage(
          id: state.pathParameters['sessionId']!,
          loadOverview: getIt<ParentPortalRepository>().sessionOverview,
        ),
      ),
      GoRoute(
        path: '/parent/plans/:planId',
        builder: (_, state) =>
            ParentLearningPlanDetailPage(id: state.pathParameters['planId']!),
      ),
      GoRoute(
        path: '/parent/targets/:targetId',
        builder: (_, state) => ParentLearningTargetDetailPage(
          id: state.pathParameters['targetId']!,
        ),
      ),
      GoRoute(
        path: '/parent/reports',
        builder: (_, state) => ParentSharedReportsPage(
          studentId: state.uri.queryParameters['studentId'],
        ),
      ),
      GoRoute(
        path: '/parent/reports/:reportId',
        builder: (_, state) =>
            ParentSharedReportDetailPage(id: state.pathParameters['reportId']!),
      ),
      GoRoute(
        path: '/parent/notifications',
        builder: (_, _) => const ParentSharedNotificationsPage(),
      ),
      GoRoute(
        path: '/parent/attendance',
        builder: (_, _) => const ParentSharedSchedulePage(attendance: true),
      ),
      GoRoute(
        path: '/parent/reschedule-requests',
        builder: (_, _) => const ParentRescheduleRequestsPage(),
      ),
      GoRoute(
        path: '/parent/materials',
        builder: (_, _) => const ActivitiesPage(role: 'parent'),
      ),
      GoRoute(
        path: '/parent/assignments/:id',
        builder: (_, state) =>
            ActivityDetailPage(id: state.pathParameters['id']!, role: 'parent'),
      ),
      GoRoute(
        path: '/parent/profile',
        builder: (_, _) => const ParentProfilePage(),
      ),
      GoRoute(
        path: '/student/sessions/:sessionId',
        builder: (_, state) =>
            StudentSessionDetailPage(id: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/student/plans/:planId',
        builder: (_, state) =>
            StudentPlanDetailPage(id: state.pathParameters['planId']!),
      ),
      GoRoute(
        path: '/student/targets/:targetId',
        builder: (_, state) =>
            StudentTargetDetailPage(id: state.pathParameters['targetId']!),
      ),
      GoRoute(
        path: '/student/reports/:reportId',
        builder: (_, state) =>
            StudentReportDetailPage(id: state.pathParameters['reportId']!),
      ),
      GoRoute(
        path: '/student/attendance',
        builder: (_, _) => const StudentAttendancePage(),
      ),
      GoRoute(
        path: '/student/materials',
        builder: (_, _) => const ActivitiesPage(role: 'student'),
      ),
      GoRoute(
        path: '/student/assignments/:id',
        builder: (_, state) => ActivityDetailPage(
          id: state.pathParameters['id']!,
          role: 'student',
        ),
      ),
      GoRoute(
        path: '/student/notifications',
        builder: (_, _) => const StudentNotificationsPage(),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (_, _) => const StudentProfilePage(),
      ),
      GoRoute(
        path: '/student/help',
        builder: (_, _) => const StudentHelpPage(),
      ),
    ],
  );
}

class TeacherShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const TeacherShell({super.key, required this.shell});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HomeStyle.cream,
    body: shell,
    bottomNavigationBar: TeacherBottomNavigation(
      selectedIndex: shell.currentIndex,
      // Selecting a bottom tab always opens its root, including when returning
      // from a detail/form; do not restore a stale detail as the entry screen.
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: true),
    ),
  );
}

class NalaraApp extends StatefulWidget {
  const NalaraApp({super.key});
  @override
  State<NalaraApp> createState() => _NalaraAppState();
}

class _NalaraAppState extends State<NalaraApp> with WidgetsBindingObserver {
  late final auth = getIt<AuthCubit>();
  late final reset = getIt<PasswordResetCubit>();
  late final push = getIt<PushNotificationService>();
  late final subscription = getIt<SubscriptionCubit>();
  late final refresh = AuthRouterRefresh(auth, reset, subscription);
  late final router = buildRouter(auth, refresh, reset, subscription);
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<SubscriptionState> _subscriptionStatus;
  StreamSubscription<NotificationTap>? _pushSubscription;
  NotificationTap? _queuedTap;
  int _pushSyncGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<ApiClient>().onSubscriptionRequired = subscription.paywall;
    _subscriptionStatus = subscription.stream.listen(
      (_) => _flushQueuedTap(auth.state),
    );
    _authSubscription = auth.stream.listen((state) {
      _syncSubscription(state);
      unawaited(_syncPush(state));
      _flushQueuedTap(state);
    });
    _pushSubscription = push.taps.listen(_handlePushTap);
    final pending = push.takePendingTap();
    if (pending != null) _handlePushTap(pending);
    unawaited(_syncPush(auth.state));
    _syncSubscription(auth.state);
  }

  void _syncSubscription(AuthState state) {
    if (state.status == AuthStatus.authenticated && state.teacher != null) {
      unawaited(subscription.activate(state.teacher!.id));
    } else {
      subscription.reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        auth.state.status == AuthStatus.authenticated) {
      unawaited(subscription.refresh(synchronizePayment: true));
    }
  }

  Future<void> _syncPush(AuthState state) async {
    final generation = ++_pushSyncGeneration;
    if (state.status == AuthStatus.authenticated) {
      await push.activateTeacher();
    } else if (state.status == AuthStatus.portalAuthenticated) {
      if (state.accessProfile?.role == AppRole.student) {
        await push.activateStudent();
      } else {
        await push.activateParent();
      }
    } else {
      await push.deactivate();
    }
    if (generation != _pushSyncGeneration || !mounted) return;
    _flushQueuedTap(state);
  }

  void _handlePushTap(NotificationTap tap) {
    final state = auth.state;
    if (_canOpenPushRoute(state, tap.route)) {
      router.go(tap.route);
    } else {
      _queuedTap = tap;
    }
  }

  void _flushQueuedTap(AuthState state) {
    final tap = _queuedTap;
    if (tap == null || !_canOpenPushRoute(state, tap.route)) return;
    _queuedTap = null;
    router.go(tap.route);
  }

  bool _canOpenPushRoute(AuthState state, String route) {
    if (state.status == AuthStatus.authenticated) {
      return subscription.accountId == state.teacher?.id &&
          subscription.state.value != null &&
          !subscription.state.blocked &&
          !subscription.state.loading &&
          route.startsWith('/teacher/');
    }
    if (state.status != AuthStatus.portalAuthenticated) return false;
    if (state.accessProfile?.role == AppRole.parent) {
      return route.startsWith('/parent/');
    }
    return route.startsWith('/student/');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    getIt<ApiClient>().onSubscriptionRequired = null;
    _pushSubscription?.cancel();
    _authSubscription.cancel();
    _subscriptionStatus.cancel();
    router.dispose();
    refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'NALARA',
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    routerConfig: router,
  );
}
