class AmbienteFolhioConfig {
  const AmbienteFolhioConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'FOLHIO_API_BASE_URL',
    defaultValue: 'https://flyover-army-handed.ngrok-free.dev',
  );

  static const appApiKey = String.fromEnvironment('FOLHIO_APP_API_KEY');

  static const appVersion = String.fromEnvironment(
    'FOLHIO_APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  static const apiProxyBypassHeader = String.fromEnvironment(
    'FOLHIO_API_PROXY_BYPASS_HEADER',
    defaultValue: '',
  );

  static const apiProxyBypassValue = String.fromEnvironment(
    'FOLHIO_API_PROXY_BYPASS_VALUE',
    defaultValue: 'true',
  );

  static const folhioGoogleClientId = String.fromEnvironment(
    'FOLHIO_GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: folhioGoogleClientId,
  );
}
