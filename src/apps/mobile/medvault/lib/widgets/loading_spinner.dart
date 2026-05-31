import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({
    super.key,
    this.size = 28,
    this.strokeWidth = 3,
    this.color,
    this.semanticLabel,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        semanticLabel ??
        AppLocalizations.of(context)?.loadingInProgress ??
        'Loading, please wait';

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? theme.colorScheme.primary,
        semanticsLabel: label,
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.semanticLabel,
    this.blockInteractions = false,
    this.scrimColor,
    this.spinnerSize = 32,
  });

  final Widget child;
  final bool isLoading;
  final String? message;
  final String? semanticLabel;
  final bool blockInteractions;
  final Color? scrimColor;
  final double spinnerSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overlayColor =
        scrimColor ?? theme.colorScheme.scrim.withValues(alpha: 0.12);

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !blockInteractions,
              child: ColoredBox(
                color: overlayColor,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 136),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LoadingSpinner(
                          size: spinnerSize,
                          semanticLabel: semanticLabel,
                        ),
                        if (message != null && message!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
