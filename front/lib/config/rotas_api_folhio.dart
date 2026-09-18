class RotasApiFolhio {
  const RotasApiFolhio._();

  static const actions = '/api/folhio/actions';
  static const upload = '/api/folhio/files/upload';
  static const clientLogs = '/api/folhio/logs/client';
  static const register = '/api/folhio/auth/register';
  static const login = '/api/folhio/auth/login';
  static const google = '/api/folhio/auth/google';
  static const refresh = '/api/folhio/auth/refresh';
  static const logout = '/api/folhio/auth/logout';
  static const forgotPassword = '/api/folhio/auth/password/forgot';
  static const resetPassword = '/api/folhio/auth/password/reset';
  static const profile = '/api/folhio/auth/me';
  static const account = '/api/folhio/auth/me/account';
  static const verifyTwoFactor = '/api/folhio/auth/2fa/verify';
  static const twoFactor = '/api/folhio/auth/me/2fa';
  static const catalog = '/api/folhio/materials/catalog';
  static const templates = '/api/folhio/materials/templates';
  static const generated = '/api/folhio/materials/generated';
  static const buildMaterial = '/api/folhio/materials/build';

  static String arquivo(String id) =>
      '/api/folhio/files/${Uri.encodeComponent(id)}';
  static String baixar(String id) => '${arquivo(id)}/download';
  static String visualizar(String id, int page) =>
      '${arquivo(id)}/preview?page=$page';
}
