// ignore_for_file: non_constant_identifier_names

class UserSession {
  static int? user_id;
  static String? name;
  static String? email;
  static String? accessToken;

  static bool get isAuthenticated =>
      user_id != null && accessToken != null && accessToken!.isNotEmpty;

  static void clear() {
    user_id = null;
    name = null;
    email = null;
    accessToken = null;
  }
}
