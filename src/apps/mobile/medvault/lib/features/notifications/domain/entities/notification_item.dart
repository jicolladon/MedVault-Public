enum NotificationItemType {
  emergencyQrAccessed,
  shareRequest,
  profileUpdated,
  providerAccess,
  medicationReminder,
  appointmentAlert,
  securityAlert,
  recordUpdated,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.relatedLinkId,
    required this.language,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.actorName,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final NotificationItemType type;
  final String? relatedLinkId;
  final String? language;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? actorName;
  final DateTime createdAt;
  final bool isRead;
}
