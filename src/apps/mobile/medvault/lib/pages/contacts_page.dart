import 'package:flutter/material.dart';
import '../widgets/custom_dialog.dart';

import '../core/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final List<Map<String, String>> _contacts = [
    {
      'name': 'Dr. Jane Smith',
      'email': 'jane.smith@hospital.org',
      'type': 'physician',
      'expires': '2026-12-01',
    },
    {
      'name': 'Emergency Access',
      'email': 'QR token (temporary)',
      'type': 'emergency',
      'expires': '2026-04-01',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: _quickAction(
                context,
                title: t?.sharingEmergencyQrTitle ?? 'Emergency QR',
                subtitle: t?.sharingQuickAccessSubtitle ?? 'Quick access',
                icon: Icons.qr_code,
                colors: const [Color(0xFFEF4444), Color(0xFFF97316)],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _quickAction(
                context,
                title: t?.sharingWithPhysicianTitle ?? 'Share with Doctor',
                subtitle: t?.sharingSecureSharingSubtitle ?? 'Secure sharing',
                icon: Icons.person_add_alt_1,
                colors: const [Color(0xFF06B6D4), Color(0xFF14B8A6)],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t?.sharingActiveSharesTitle ?? 'Active Shares',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Chip(label: Text('${_contacts.length}')),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._contacts.map((contact) {
                  final isEmergency = contact['type'] == 'emergency';
                  return Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isEmergency
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDBF5F7),
                          child: Icon(
                            isEmergency
                                ? Icons.health_and_safety_outlined
                                : Icons.person_outline,
                            color: isEmergency
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? '',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                contact['email'] ?? '',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '${t?.sharingExpiresLabel ?? 'Expires'}: ${contact['expires']}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAddContactDialog(context),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => _showAddContactDialog(context),
          icon: const Icon(Icons.person_add),
          label: Text(t?.sharingAddShareContactButton ?? 'Add Share Contact'),
        ),
      ],
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () => _showAddContactDialog(context),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final t = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        title: t?.addContact ?? 'Add Contact',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t?.name ?? 'Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: t?.email ?? 'Email',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: t?.phone ?? 'Phone',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _contacts.add({
                    'name': nameController.text,
                    'email': emailController.text,
                    'type': 'physician',
                    'expires': '2026-12-31',
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text(t?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }
}
