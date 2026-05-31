import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/notifications_models.dart';
import '../services/connectivity_service.dart';
import '../services/notifications_service.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/medvault_page_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _tabAll = 0;
  static const int _tabUnread = 1;

  int _selectedTab = _tabAll;
  late final NotificationsService _notificationsService;
  ConnectivityService? _connectivityService;

  List<MedVaultNotification> get _visibleItems {
    if (_selectedTab == _tabUnread) {
      return _notificationsService.notifications
          .where((item) => !item.isRead)
          .toList(growable: false);
    }

    return _notificationsService.notifications;
  }

  @override
  void initState() {
    super.initState();
    _notificationsService = ServiceLocator.instance.notificationsService;
    _notificationsService.addListener(_onServiceChanged);
    try {
      _connectivityService = ServiceLocator.instance.connectivityService;
      _connectivityService?.addListener(_onServiceChanged);
    } catch (_) {
      _connectivityService = null;
    }
    _initialize();
  }

  Future<void> _initialize() async {
    await _notificationsService.initialize();
  }

  @override
  void dispose() {
    _notificationsService.removeListener(_onServiceChanged);
    _connectivityService?.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final isOffline = _connectivityService?.isOffline ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t.notificationsPageTitle,
            subtitle: t.notificationsUnreadCount(
              _notificationsService.unreadCount,
            ),
            leading: canPop
                ? IconButton(
                    tooltip: t.onboardingBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _tabButton(
                    key: const Key('notifications_tab_all'),
                    label: t.notificationsTabAll,
                    index: _tabAll,
                  ),
                  _tabButton(
                    key: const Key('notifications_tab_unread'),
                    label: t.notificationsTabUnread,
                    index: _tabUnread,
                  ),
                ],
              ),
            ),
          ),
          if (isOffline)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Offline mode: showing saved notifications. '
                  'Live updates resume when internet is restored.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _notificationsService.isLoading && _visibleItems.isEmpty
                ? Center(
                    child: LoadingSpinner(semanticLabel: t.loadingInProgress),
                  )
                : _notificationsService.hasSyncError && _visibleItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.error,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: isOffline
                                ? null
                                : () => _notificationsService
                                      .fetchNotifications(),
                            child: Text(t.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : _visibleItems.isEmpty
                ? Center(
                    child: Text(
                      _selectedTab == _tabUnread
                          ? t.notificationsUnreadEmpty
                          : t.notificationsAllEmpty,
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : Column(
                    children: [
                      if (_notificationsService.hasSyncError)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.error,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => isOffline
                              ? Future.value()
                              : _notificationsService.fetchNotifications(),
                          child: ListView.builder(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: _visibleItems.length,
                            itemBuilder: (context, index) {
                              final item = _visibleItems[index];
                              final style = _notificationStyle(
                                item.type,
                                theme,
                              );
                              final card = Container(
                                key: Key('notification_item_${item.id}'),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: !item.isRead
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant,
                                    width: !item.isRead ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    12,
                                    12,
                                  ),
                                  onTap: () => _onNotificationTap(item),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: style.iconBackground,
                                    child: Icon(
                                      style.icon,
                                      color: style.iconColor,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    _notificationTitle(t, item),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_notificationSubtitle(item)
                                          case final subtitle?) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        _notificationDescription(t, item),
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _relativeTimeLabel(t, item.createdAt),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  trailing: !item.isRead
                                      ? Icon(
                                          Icons.circle,
                                          color: theme.colorScheme.primary,
                                          size: 8,
                                        )
                                      : null,
                                ),
                              );

                              if (item.isRead) {
                                return Opacity(opacity: 0.65, child: card);
                              }

                              return card;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationTap(MedVaultNotification item) async {
    final t = AppLocalizations.of(context)!;

    try {
      await _notificationsService.markAsRead(item.id);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final typeLabel = _notificationTypeLabel(t, item.type);
          final subtitle = _notificationSubtitle(item);

          return AlertDialog(
            key: const Key('notification_detail_dialog'),
            title: Text(t.notificationsDetailTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _notificationTitle(t, item),
                    key: const Key('notification_detail_value_title'),
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(dialogContext).textTheme.bodyMedium
                          ?.copyWith(
                            color: Theme.of(
                              dialogContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _NotificationDetailRow(
                    label: t.notificationsDetailTypeLabel,
                    value: typeLabel,
                  ),
                  _NotificationDetailRow(
                    label: t.notificationsDetailReceivedAtLabel,
                    value: _absoluteTimeLabel(dialogContext, item.createdAt),
                  ),
                  _NotificationDetailRow(
                    label: t.notificationsDetailStatusLabel,
                    value: item.isRead
                        ? t.notificationsDetailStatusRead
                        : t.notificationsDetailStatusUnread,
                  ),
                  if (item.actorName?.trim() case final actorName?
                      when actorName.isNotEmpty)
                    _NotificationDetailRow(
                      label: t.notificationsDetailActorLabel,
                      value: actorName,
                    ),
                  if (item.language?.trim() case final language?
                      when language.isNotEmpty)
                    _NotificationDetailRow(
                      label: t.notificationsDetailLanguageLabel,
                      value: language,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    t.notificationsDetailDescriptionLabel,
                    style: Theme.of(dialogContext).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _notificationDescription(t, item),
                    key: const Key('notification_detail_value_description'),
                    style: Theme.of(dialogContext).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                key: const Key('notification_detail_action_close'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.notificationsDetailCloseAction),
              ),
            ],
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.notificationsDetailOpenError)));
    }
  }

  Widget _tabButton({
    required Key key,
    required String label,
    required int index,
  }) {
    final active = _selectedTab == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: active ? Theme.of(context).colorScheme.surface : null,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  _NotificationStyle _notificationStyle(
    NotificationType type,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    switch (type) {
      case NotificationType.emergencyQrAccessed:
      case NotificationType.securityAlert:
        return _NotificationStyle(
          icon: Icons.shield_outlined,
          iconBackground: colorScheme.errorContainer,
          iconColor: colorScheme.onErrorContainer,
        );
      case NotificationType.shareRequest:
      case NotificationType.providerAccess:
        return _NotificationStyle(
          icon: Icons.share,
          iconBackground: colorScheme.primaryContainer,
          iconColor: colorScheme.onPrimaryContainer,
        );
      case NotificationType.profileUpdated:
      case NotificationType.recordUpdated:
        return _NotificationStyle(
          icon: Icons.notifications_none,
          iconBackground: colorScheme.surfaceContainerHighest,
          iconColor: colorScheme.onSurfaceVariant,
        );
      case NotificationType.medicationReminder:
        return _NotificationStyle(
          icon: Icons.medication_outlined,
          iconBackground: colorScheme.tertiaryContainer,
          iconColor: colorScheme.onTertiaryContainer,
        );
      case NotificationType.appointmentAlert:
        return _NotificationStyle(
          icon: Icons.calendar_today_outlined,
          iconBackground: colorScheme.secondaryContainer,
          iconColor: colorScheme.onSecondaryContainer,
        );
    }
  }

  String _notificationTitle(AppLocalizations t, MedVaultNotification item) {
    final customTitle = item.title?.trim();
    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }

    return _notificationTypeLabel(t, item.type);
  }

  String _notificationTypeLabel(AppLocalizations t, NotificationType type) {
    switch (type) {
      case NotificationType.emergencyQrAccessed:
        return t.notificationsTypeEmergencyQrAccessedTitle;
      case NotificationType.shareRequest:
        return t.notificationsTypeShareRequestTitle;
      case NotificationType.profileUpdated:
        return t.notificationsTypeProfileUpdatedTitle;
      case NotificationType.providerAccess:
        return t.notificationsTypeProviderAccessTitle;
      case NotificationType.medicationReminder:
        return t.notificationsTypeMedicationReminderTitle;
      case NotificationType.appointmentAlert:
        return t.notificationsTypeAppointmentAlertTitle;
      case NotificationType.securityAlert:
        return t.notificationsTypeSecurityAlertTitle;
      case NotificationType.recordUpdated:
        return t.notificationsTypeRecordUpdatedTitle;
    }
  }

  String _notificationDescription(
    AppLocalizations t,
    MedVaultNotification item,
  ) {
    final customDescription = item.description?.trim();
    if (customDescription != null && customDescription.isNotEmpty) {
      return customDescription;
    }

    final actor = item.actorName ?? t.unknownUser;

    switch (item.type) {
      case NotificationType.emergencyQrAccessed:
        return t.notificationsTypeEmergencyQrAccessedDescription;
      case NotificationType.shareRequest:
        return t.notificationsTypeShareRequestDescription(actor);
      case NotificationType.profileUpdated:
        return t.notificationsTypeProfileUpdatedDescription;
      case NotificationType.providerAccess:
        return t.notificationsTypeProviderAccessDescription(actor);
      case NotificationType.medicationReminder:
        return t.notificationsTypeMedicationReminderDescription;
      case NotificationType.appointmentAlert:
        return t.notificationsTypeAppointmentAlertDescription;
      case NotificationType.securityAlert:
        return t.notificationsTypeSecurityAlertDescription;
      case NotificationType.recordUpdated:
        return t.notificationsTypeRecordUpdatedDescription;
    }
  }

  String? _notificationSubtitle(MedVaultNotification item) {
    final value = item.subtitle?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value.replaceAll(
      '{unreadCount}',
      _notificationsService.unreadCount.toString(),
    );
  }

  String _relativeTimeLabel(AppLocalizations t, DateTime createdAt) {
    final now = DateTime.now();
    final duration = now.difference(createdAt);

    if (duration.inMinutes < 1) {
      return t.notificationsJustNow;
    }

    if (duration.inHours < 1) {
      return t.notificationsMinutesAgo(duration.inMinutes);
    }

    if (duration.inDays < 1) {
      return t.notificationsHoursAgo(duration.inHours);
    }

    return t.notificationsDaysAgo(duration.inDays);
  }

  String _absoluteTimeLabel(BuildContext context, DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final date = localizations.formatFullDate(localDateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localDateTime),
      alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
    );
    return '$date, $time';
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _NotificationStyle({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _NotificationDetailRow extends StatelessWidget {
  const _NotificationDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
