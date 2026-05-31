class AppSettings {
  const AppSettings({
    required this.useBiometric,
    required this.isAceFirstTime,
    required this.darkModeEnabled,
  });

  final bool useBiometric;
  final bool isAceFirstTime;
  final bool darkModeEnabled;

  const AppSettings.defaults()
    : useBiometric = true,
      isAceFirstTime = true,
      darkModeEnabled = false;

  AppSettings copyWith({
    bool? useBiometric,
    bool? isAceFirstTime,
    bool? darkModeEnabled,
  }) {
    return AppSettings(
      useBiometric: useBiometric ?? this.useBiometric,
      isAceFirstTime: isAceFirstTime ?? this.isAceFirstTime,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }
}
