import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../domain/entities/notification.dart';
import 'notifications_style.dart';

class NotificationCard extends StatelessWidget {
  final TeacherNotification notification;
  final bool busy;
  final String? error;
  final VoidCallback? onOpen, onMarkRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.busy,
    required this.onOpen,
    required this.onMarkRead,
    this.error,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      decoration: NalaraCardStyle.decoration(
        radius: 19,
        borderColor: notification.read
            ? NotificationsStyle.line
            : NotificationsStyle.unreadLine,
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('notification-open-${notification.id}'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!notification.read) ...[
                  Text(
                    'Baru',
                    style: NotificationsStyle.body.copyWith(
                      fontSize: 11,
                      color: NotificationsStyle.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  notification.title,
                  style: NotificationsStyle.body.copyWith(
                    color: NotificationsStyle.ink,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(notification.body, style: NotificationsStyle.body),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${DateTimeUtils.full(notification.createdAt)} WIB',
                      style: NotificationsStyle.body.copyWith(fontSize: 11),
                    ),
                    if (!notification.read)
                      TextButton(
                        key: ValueKey('notification-read-${notification.id}'),
                        onPressed: onMarkRead,
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Tandai dibaca'),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Dibaca',
                          style: NotificationsStyle.body.copyWith(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      error!,
                      key: ValueKey('notification-error-${notification.id}'),
                      style: NotificationsStyle.body.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
