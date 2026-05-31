import 'dart:convert';

enum NotificationType {
  emergencyQrAccessed,
  shareRequest,
  profileUpdated,
  providerAccess,
  medicationReminder,
  appointmentAlert,
  securityAlert,
  recordUpdated,
}

class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool securityAlerts;
  final bool dataSharingNotifications;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? language;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.securityAlerts = true,
    this.dataSharingNotifications = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.language,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? securityAlerts,
    bool? dataSharingNotifications,
    String? quietHoursStart,
    bool clearQuietHoursStart = false,
    String? quietHoursEnd,
    bool clearQuietHoursEnd = false,
    String? language,
    bool clearLanguage = false,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      dataSharingNotifications:
          dataSharingNotifications ?? this.dataSharingNotifications,
      quietHoursStart: clearQuietHoursStart
          ? null
          : (quietHoursStart ?? this.quietHoursStart),
      quietHoursEnd: clearQuietHoursEnd
          ? null
          : (quietHoursEnd ?? this.quietHoursEnd),
      language: clearLanguage ? null : (language ?? this.language),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'securityAlerts': securityAlerts,
      'dataSharingNotifications': dataSharingNotifications,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'language': language,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      securityAlerts: json['securityAlerts'] ?? true,
      dataSharingNotifications: json['dataSharingNotifications'] ?? true,
      quietHoursStart: json['quietHoursStart']?.toString(),
      quietHoursEnd: json['quietHoursEnd']?.toString(),
      language: json['language']?.toString(),
    );
  }

  static String encode(NotificationSettings value) {
    return jsonEncode(value.toJson());
  }

  static NotificationSettings decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const NotificationSettings();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const NotificationSettings();
    }

    return NotificationSettings.fromJson(Map<String, dynamic>.from(decoded));
  }
}

class MedVaultNotification {
  final String id;
  final NotificationType type;
  final String? relatedLinkId;
  final String? language;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? actorName;
  final DateTime createdAt;
  final bool isRead;

  const MedVaultNotification({
    required this.id,
    required this.type,
    this.relatedLinkId,
    required this.language,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.actorName,
    required this.createdAt,
    required this.isRead,
  });

  MedVaultNotification copyWith({
    String? id,
    NotificationType? type,
    String? relatedLinkId,
    bool clearRelatedLinkId = false,
    String? language,
    bool clearLanguage = false,
    String? title,
    bool clearTitle = false,
    String? subtitle,
    bool clearSubtitle = false,
    String? description,
    bool clearDescription = false,
    String? actorName,
    bool clearActorName = false,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return MedVaultNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      relatedLinkId: clearRelatedLinkId
          ? null
          : (relatedLinkId ?? this.relatedLinkId),
      language: clearLanguage ? null : (language ?? this.language),
      title: clearTitle ? null : (title ?? this.title),
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      description: clearDescription ? null : (description ?? this.description),
      actorName: clearActorName ? null : (actorName ?? this.actorName),
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'relatedLinkId': relatedLinkId,
      'language': language,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'actorName': actorName,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory MedVaultNotification.fromJson(Map<String, dynamic> json) {
    return MedVaultNotification(
      id: json['id']?.toString() ?? '',
      type: NotificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => NotificationType.securityAlert,
      ),
      relatedLinkId:
          json['relatedLinkId']?.toString() ??
          json['shareLinkId']?.toString() ??
          json['linkId']?.toString(),
      language: json['language']?.toString(),
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      actorName: json['actorName']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  static String encodeList(List<MedVaultNotification> values) {
    return jsonEncode(values.map((value) => value.toJson()).toList());
  }

  static List<MedVaultNotification> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (value) =>
              MedVaultNotification.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }
}
