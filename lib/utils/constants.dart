import 'package:flutter/foundation.dart';

abstract final class ApiConstants {
  static const prefix = '/api/v1';
  static const androidDevBaseUrl = 'http://192.168.100.157:3100$prefix';
  static const iosDevBaseUrl = 'http://localhost:3100$prefix';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
      final uri = Uri.tryParse(_configuredBaseUrl);
      if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
        throw StateError(
          'API_BASE_URL harus berupa alamat HTTPS pada build release.',
        );
      }
    }

    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? androidDevBaseUrl
        : iosDevBaseUrl;
  }

  // Authentication
  static const login = '/auth/login';
  static const googleLogin = '/auth/google';
  static const register = '/auth/register';
  static const logout = '/auth/logout';
  static const refreshToken = '/auth/refresh';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyResetOtp = '/auth/verify-reset-otp';
  static const resetPassword = '/auth/reset-password';
  static const me = '/me';
  static const referralRedeem = '/invitations/redeem';
  static const portalMe = '/portal/me';
  static const portalRefresh = '/portal/refresh';
  static const portalLogout = '/portal/logout';
  static const portalDashboard = '/portal/dashboard';
  static const portalStudents = '/portal/students';
  static const portalSessions = '/portal/sessions';
  static const portalPlans = '/portal/plans';
  static const portalReports = '/portal/reports';
  static const portalNotifications = '/portal/notifications';
  static const portalAvailability = '/portal/availability';
  static const portalRescheduleRequests = '/portal/reschedule-requests';
  static const rescheduleRequests = '/reschedule-requests';

  // Student portal
  static const studentPortal = '/portal/student';
  static const studentPortalDashboard = '$studentPortal/dashboard';
  static const studentPortalProfile = '$studentPortal/profile';
  static const studentPortalSessions = '$studentPortal/sessions';
  static const studentPortalPlans = '$studentPortal/plans';
  static const studentPortalReports = '$studentPortal/reports';
  static const studentPortalNotifications = '$studentPortal/notifications';
  static const studentPortalNotificationDevices =
      '$studentPortalNotifications/devices';
  static const studentPortalNotificationsReadAll =
      '$studentPortalNotifications/read-all';

  // Dashboard and teaching data
  static const healthLive = '/health/live';
  static const healthReady = '/health/ready';
  static const dashboard = '/dashboard';
  static const teachingGuide = '/teaching-guide';
  static const teachingGuidePreferences = '$teachingGuide/preferences';
  static const accountDeletion = '/account-deletion';
  static const students = '/students';
  static const families = '/families';
  static const subjects = '/subjects';
  static const schedules = '/schedules';
  static const sessions = '/sessions';
  static const learningPlans = '/learning-plans';
  static const targets = '/targets';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const notificationDevices = '$notifications/devices';
  static const notificationsReadAll = '$notifications/read-all';
  static const subscriptionCurrent = '/subscriptions/current';
  static const subscriptionSync = '/subscriptions/sync';
  static const subscriptionCheckout = '/subscriptions/checkout';
  static const subscriptionPayments = '/subscriptions/payments';
  static String subscriptionPaymentRefresh(String id) =>
      '$subscriptionPayments/$id/refresh';
  static String subscriptionPaymentCancel(String id) =>
      '$subscriptionPayments/$id/cancel';
  static const tutorTools = '/tutor-tools';
  static const assignments = '$tutorTools/assignments';
  static const reportTemplates = '$tutorTools/templates';
  static const progressAnalytics = '$tutorTools/analytics';
  static const tutorBranding = '$tutorTools/branding';
  static const tutorBrandingLogo = '$tutorBranding/logo';
  static const tutorNotificationPreferences =
      '$tutorTools/notification-preferences';
  static const exportData = '$tutorTools/export';
  static const portalAssignments = '/portal/assignments';
  static String assignment(String id) => '$assignments/$id';
  static String portalAssignment(String id) => '$portalAssignments/$id';
  static String assignmentSubmission(String id) =>
      '${portalAssignment(id)}/submission';
  static String submissionFeedback(String id) =>
      '$tutorTools/submissions/$id/feedback';
  static String reportTemplate(String id) => '$reportTemplates/$id';
  static String reportPdf(String id) => '$tutorTools/reports/$id/pdf';

  // Dynamic endpoint paths
  static String student(String id) => '$students/$id';
  static String studentSummary(String id) => '${student(id)}/summary';
  static String subject(String id) => '$subjects/$id';
  static String family(String id) => '$families/$id';
  static String familyInvitations(String id) => '${family(id)}/invitations';
  static String revokeFamilyInvitation(String id, String invitationId) =>
      '${familyInvitations(id)}/$invitationId/revoke';
  static String revokeFamilyAccess(String id) => '${family(id)}/access/revoke';
  static String revokeStudentAccess(String id) =>
      '${student(id)}/access/revoke';
  static String studentInvitations(String id) => '${student(id)}/invitations';
  static String revokeStudentInvitation(String id, String invitationId) =>
      '${studentInvitations(id)}/$invitationId/revoke';

  static String schedule(String id) => '$schedules/$id';
  static String session(String id) => '$sessions/$id';
  static String sessionAttendance(String id) => '${session(id)}/attendance';

  static String learningPlan(String id) => '$learningPlans/$id';
  static String learningPlanTargets(String planId) =>
      '${learningPlan(planId)}/targets';
  static String target(String id) => '$targets/$id';
  static String targetProgress(String id) => '${target(id)}/progress';
  static String targetHistory(String id) => '${target(id)}/history';

  static String report(String id) => '$reports/$id';
  static String sessionReports(String sessionId) =>
      '${session(sessionId)}/reports';
  static String sessionReport(String sessionId, String reportId) =>
      '${sessionReports(sessionId)}/$reportId';
  static String publishSessionReport(String sessionId, String reportId) =>
      '${sessionReport(sessionId, reportId)}/publish';

  static String notificationRead(String id) => '$notifications/$id/read';
  static const portalNotificationDevices = '$portalNotifications/devices';
  static const portalNotificationsReadAll = '$portalNotifications/read-all';
  static String portalStudent(String id) => '$portalStudents/$id';
  static String portalSession(String id) => '$portalSessions/$id';
  static String portalPlan(String id) => '$portalPlans/$id';
  static String portalReport(String id) => '$portalReports/$id';
  static String portalNotificationRead(String id) =>
      '$portalNotifications/$id/read';
  static String studentPortalSession(String id) => '$studentPortalSessions/$id';
  static String studentPortalPlan(String id) => '$studentPortalPlans/$id';
  static String studentPortalTarget(String id) => '$studentPortal/targets/$id';
  static String studentPortalReport(String id) => '$studentPortalReports/$id';
  static String studentPortalNotificationRead(String id) =>
      '$studentPortalNotifications/$id/read';
  static String teacherRescheduleRequest(String id) =>
      '$rescheduleRequests/$id';
}
