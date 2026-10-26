import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../shared/widgets/nalara_avatar.dart';
import 'home_backdrop.dart';
import 'home_style.dart';

class HomeRoleHeader extends StatelessWidget {
  final String name;
  final String? avatarId;
  final String date;
  final int unreadNotifications;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final String profileTooltip;

  const HomeRoleHeader({
    super.key,
    required this.name,
    this.avatarId,
    required this.date,
    required this.unreadNotifications,
    required this.onProfile,
    required this.onNotifications,
    this.profileTooltip = 'Profil',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NALARA',
                  key: ValueKey('home-brand'),
                  style: HomeStyle.brand,
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  key: const ValueKey('home-date'),
                  style: HomeStyle.dateLabel,
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('home-notifications'),
            onPressed: onNotifications,
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              padding: const EdgeInsets.all(8),
            ),
            tooltip: unreadNotifications > 0
                ? 'Notifikasi, $unreadNotifications belum dibaca'
                : 'Notifikasi',
            icon: Badge(
              key: const ValueKey('home-notification-badge'),
              isLabelVisible: unreadNotifications > 0,
              backgroundColor: const Color(0xFFD85836),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: HomeStyle.ink,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            key: const ValueKey('home-profile'),
            onPressed: onProfile,
            tooltip: profileTooltip,
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
            icon: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E9DF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xBFFFFFFF)),
              ),
              alignment: Alignment.center,
              child: NalaraAvatar(
                name: name,
                avatarId: avatarId,
                size: 40,
                maxInitials: 1,
                backgroundColor: const Color(0xFFE0E9DF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeRoleMetric {
  final String value;
  final String label;
  final String iconAsset;
  final Color tint;
  final Color iconTint;
  final VoidCallback onTap;

  const HomeRoleMetric({
    required this.value,
    required this.label,
    required this.iconAsset,
    required this.tint,
    required this.iconTint,
    required this.onTap,
  });
}

class HomeRoleHero extends StatelessWidget {
  final String greeting;
  final String name;
  final String supporting;
  final List<HomeRoleMetric> metrics;

  const HomeRoleHero({
    super.key,
    required this.greeting,
    required this.name,
    required this.supporting,
    required this.metrics,
  }) : assert(metrics.length == 3, 'HomeRoleHero requires exactly 3 metrics');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      const inset = 18.0, gap = 8.0, cardPadding = 14.0;
      final cardWidth = (width - inset * 2 - gap * 2) / 3;
      var cardHeight = 0.0;
      for (final metric in metrics) {
        final contentWidth = math.max(1.0, cardWidth - cardPadding * 2);
        cardHeight = math.max(
          cardHeight,
          cardPadding * 2 +
              48 +
              10 +
              HomeStyle.textHeight(
                context,
                metric.value,
                HomeStyle.number,
                contentWidth,
              ) +
              3 +
              HomeStyle.textHeight(
                context,
                metric.label,
                HomeStyle.caption,
                contentWidth,
              ),
        );
      }
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(bottom: cardHeight / 2, child: const HomeBackdrop()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: width * .09),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: SizedBox(
                  width: (width - 44) * .84,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: HomeStyle.greeting),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        key: const ValueKey('home-teacher-name'),
                        style: HomeStyle.name,
                      ),
                      const SizedBox(height: 8),
                      Text(supporting, style: HomeStyle.supporting),
                    ],
                  ),
                ),
              ),
              SizedBox(height: width * .07),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                child: ConstrainedBox(
                  key: const ValueKey('home-summary-strip'),
                  // Keep the cards aligned to the measured height when the
                  // labels fit, but let the row grow if text wraps at a
                  // narrow width or a larger accessibility text scale.
                  constraints: BoxConstraints(minHeight: cardHeight),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < metrics.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: gap),
                          Expanded(
                            child: _HomeRoleMetricCard(
                              key: ValueKey(switch (index) {
                                0 => 'home-active-students',
                                1 => 'home-today-count',
                                _ => 'home-pending-reports',
                              }),
                              metric: metrics[index],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _HomeRoleMetricCard extends StatelessWidget {
  final HomeRoleMetric metric;
  const _HomeRoleMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: NalaraCardStyle.decoration(
      radius: 18,
      color: metric.tint,
      borderColor: Colors.white.withValues(alpha: .8),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: metric.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: metric.iconTint,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(metric.iconAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Text(metric.value, style: HomeStyle.number),
              const SizedBox(height: 3),
              Text(metric.label, style: HomeStyle.caption),
            ],
          ),
        ),
      ),
    ),
  );
}
