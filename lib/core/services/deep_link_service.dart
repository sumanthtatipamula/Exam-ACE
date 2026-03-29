import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();

  /// Get the initial deep link that opened the app (if any)
  static Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      return null;
    }
  }

  /// Stream of deep links received when app is already running
  static Stream<Uri> get linkStream {
    return _appLinks.uriLinkStream;
  }

  /// Parse a deep link URI and extract the route and parameters
  static Map<String, dynamic>? parseDeepLink(Uri? uri) {
    if (uri == null) return null;

    try {
      // Handle examace:// scheme (e.g. examace://reset-password?token=abc)
      if (uri.scheme == 'examace') {
        final path = '/${uri.host}';
        final params = uri.queryParameters;
        
        return {
          'path': path,
          'params': params,
        };
      }

      // Handle HTTPS URLs from Firebase hosting domain
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host == 'exam-ace-db272.web.app') {
        final path = uri.path;
        final params = uri.queryParameters;

        if (path == '/reset-password' || path == '/verify-email') {
          return {
            'path': path,
            'params': params,
          };
        }
      }
    } catch (e) {
      return null;
    }
    
    return null;
  }
}
