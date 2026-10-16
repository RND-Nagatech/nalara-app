import 'package:flutter/material.dart';
import '../../domain/entities/dashboard.dart';
import 'home_role_widgets.dart';
import 'home_style.dart';

class HomeHeader extends StatelessWidget {
  final TeacherDashboard? data;
  final VoidCallback onProfile, onNotifications;
  const HomeHeader({
    super.key,
    this.data,
    required this.onProfile,
    required this.onNotifications,
  });
  @override
  Widget build(BuildContext context) => HomeRoleHeader(
    name: data?.teacher.name ?? '',
    date: data == null ? 'Beranda Guru' : HomeStyle.date(data!),
    unreadNotifications: data?.unreadNotifications ?? 0,
    onProfile: onProfile,
    onNotifications: onNotifications,
    profileTooltip: 'Profil Guru',
  );
}
