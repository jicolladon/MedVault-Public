import 'package:flutter/material.dart';

class MedVaultPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;

  const MedVaultPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBackground =
        backgroundColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF0D6C74)
            : const Color(0xFF11B6BC));

    return Container(
      color: resolvedBackground,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HeaderSlot(child: leading),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _HeaderSlot(child: trailing),
          ],
        ),
      ),
    );
  }
}

class _HeaderSlot extends StatelessWidget {
  final Widget? child;

  const _HeaderSlot({this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 48, height: 48, child: child ?? const SizedBox());
  }
}
