import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/presentation/widgets/auth_palette.dart';
import '../../domain/entities/app_role.dart';

class EntryLayout extends StatelessWidget {
  final Widget child;
  const EntryLayout({super.key, required this.child});
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AuthPalette.cream,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'NalaraInter',
          bodyColor: AuthPalette.ink,
          displayColor: AuthPalette.ink,
        ),
      ),
      child: Scaffold(
        backgroundColor: AuthPalette.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

extension RoleAppearance on AppRole {
  String get label => switch (this) {
    AppRole.teacher => 'Guru',
    AppRole.student => 'Siswa',
    AppRole.parent => 'Orang Tua',
  };
  String get illustration =>
      'assets/Role/${switch (this) {
        AppRole.teacher => 'Guru',
        AppRole.student => 'Siswa',
        AppRole.parent => 'Orang tua',
      }}.png';
  String get entryRoute => switch (this) {
    AppRole.teacher => '/login',
    AppRole.student => '/student/referral',
    AppRole.parent => '/parent/referral',
  };
}
