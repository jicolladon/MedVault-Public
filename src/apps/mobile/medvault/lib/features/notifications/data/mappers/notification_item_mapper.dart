import '../../../../models/notifications_models.dart';
import '../../domain/entities/notification_item.dart';

NotificationItem mapNotificationItem(MedVaultNotification item) {
  return NotificationItem(
    id: item.id,
    type: _mapNotificationType(item.type),
    relatedLinkId: item.relatedLinkId,
    language: item.language,
    title: item.title,
    subtitle: item.subtitle,
    description: item.description,
    actorName: item.actorName,
    createdAt: item.createdAt,
    isRead: item.isRead,
  );
}

NotificationItemType _mapNotificationType(NotificationType type) {
  switch (type) {
    case NotificationType.emergencyQrAccessed:
      return NotificationItemType.emergencyQrAccessed;
    case NotificationType.shareRequest:
      return NotificationItemType.shareRequest;
    case NotificationType.profileUpdated:
      return NotificationItemType.profileUpdated;
    case NotificationType.providerAccess:
      return NotificationItemType.providerAccess;
    case NotificationType.medicationReminder:
      return NotificationItemType.medicationReminder;
    case NotificationType.appointmentAlert:
      return NotificationItemType.appointmentAlert;
    case NotificationType.securityAlert:
      return NotificationItemType.securityAlert;
    case NotificationType.recordUpdated:
      return NotificationItemType.recordUpdated;
  }
}
