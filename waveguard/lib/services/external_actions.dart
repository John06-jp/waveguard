import 'package:url_launcher/url_launcher.dart';

abstract interface class ExternalActions {
  Future<bool> open(Uri uri);
}

class PlatformExternalActions implements ExternalActions {
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
