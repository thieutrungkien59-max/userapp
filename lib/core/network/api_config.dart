/// One switchable location for the backend endpoint.
///
/// The default is the public ngrok tunnel shared by the backend team.
/// Override it without changing source code when the server address changes:
/// `flutter run --dart-define=API_BASE_URL=http://<host>:5262`
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://startle-kilogram-greeting.ngrok-free.dev',
  );
}
