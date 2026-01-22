/// PlayStation Network API constants
class PsnApi {
  PsnApi._();

  /// OAuth base URL
  static const String oauthBaseUrl =
      'https://ca.account.sony.com/api/authz/v3/oauth';

  /// Media API base URL
  static const String mediaApiBaseUrl =
      'https://m.np.playstation.com/api/gameMediaService/v2/c2s/category/cloudMediaGallery/ugcType/all';

  /// OAuth client ID (PlayStation Android app)
  static const String clientId = '09515159-7237-4370-9b40-3806e67c0891';

  /// OAuth redirect URI
  static const String redirectUri =
      'com.scee.psxandroid.scecompcall://redirect';

  /// OAuth scopes
  static const String scopes = 'psn:mobile.v2.core psn:clientapp';

  /// Login URL for WebView
  static const String loginUrl =
      'https://id.sonyentertainmentnetwork.com/id/management_ca/';

  /// Domain to check for NPSSO cookie
  static const String cookieDomain = 'ca.account.sony.com';

  /// Logout URL to clear server-side session
  static const String logoutUrl =
      'https://web.np.playstation.com/api/session/v1//signout?redirect_uri=https://io.playstation.com/central/auth/logout?locale=en_US';
}
