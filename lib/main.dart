import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/password_reset_cubit.dart';
import 'firebase_options.dart';
import 'utils/injector.dart';
import 'shared/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  tz.initializeTimeZones();
  await initializeDateFormatting('id_ID');
  await configureDependencies();
  await getIt<PushNotificationService>().initialize();
  await getIt<PasswordResetCubit>().restore();
  runApp(const NalaraApp());
  unawaited(getIt<AuthCubit>().restore());
}
