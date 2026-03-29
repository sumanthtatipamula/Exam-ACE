import 'package:flutter/services.dart';

class DeepLinkService {
  static const platform = MethodChannel('com.examace.exam_ace/deeplink');
  static const eventChannel = EventChannel('com.examace.exam_ace/deeplink_stream');

  /// Get the initial deep link that opened the app (if any)
  static Future<String?> getInitialLink() async {
    try {
      final String? link = await platform.invokeMethod('getInitialLink');
      return link;
    } catch (e) {
      print('Error getting initial link: $e');
      return null;
    }
  }

  /// Stream of deep links received when app is already running
  static Stream<String> get linkStream {
    return eventChannel.receiveBroadcastStream().map((dynamic link) => link as String);
  }

  /// Parse a deep link URL and extract the route and parameters
  static Map<String, dynamic>? parseDeepLink(String? link) {
    if (link == null || link.isEmpty) return null;

    try {
      final uri = Uri.parse(link);
      
      // Handle examace:// scheme
      if (uri.scheme == 'examace') {
        final path = '/${uri.host}';
        final params = uri.queryParameters;
        
        return {
          'path': path,
          'params': params,
        };
      }
    } catch (e) {
      print('Error parsing deep link: $e');
    }
    
    return null;
  }
}
