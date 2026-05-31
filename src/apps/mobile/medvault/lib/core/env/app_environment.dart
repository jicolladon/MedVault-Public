enum AppEnvironment { demo, development, production }

AppEnvironment parseAppEnvironment(String raw) {
  switch (raw.toLowerCase()) {
    case 'demo':
      return AppEnvironment.demo;
    case 'development':
      return AppEnvironment.development;
    case 'production':
      return AppEnvironment.production;
    default:
      return AppEnvironment.demo;
  }
}
