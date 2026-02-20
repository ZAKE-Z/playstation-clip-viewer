/// Upload configuration parsed from ShareX .sxcu or equivalent.
/// Supports ImageUploader, FileUploader style configs.
class UploadConfig {
  final String name;
  final String requestUrl;
  final String requestMethod;
  final Map<String, String> headers;
  final String body;
  final String fileFormName;
  /// ShareX URL field: {response}, {json:path}, etc. Used to parse response.
  final String? urlTemplate;

  const UploadConfig({
    required this.name,
    required this.requestUrl,
    this.requestMethod = 'POST',
    this.headers = const {},
    this.body = 'MultipartFormData',
    this.fileFormName = 'file',
    this.urlTemplate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'requestUrl': requestUrl,
        'requestMethod': requestMethod,
        'headers': headers,
        'body': body,
        'fileFormName': fileFormName,
        'urlTemplate': urlTemplate,
      };

  factory UploadConfig.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    Map<String, String> headers = {};
    if (headersRaw is Map) {
      for (final e in headersRaw.entries) {
        if (e.value != null) {
          headers[e.key.toString()] = e.value.toString();
        }
      }
    }
    return UploadConfig(
      name: json['name'] as String? ?? '',
      requestUrl: json['requestUrl'] as String? ?? '',
      requestMethod: json['requestMethod'] as String? ?? 'POST',
      headers: headers,
      body: json['body'] as String? ?? 'MultipartFormData',
      fileFormName: json['fileFormName'] as String? ?? 'file',
      urlTemplate: json['urlTemplate'] as String?,
    );
  }

  /// Parse from ShareX .sxcu JSON
  static UploadConfig? fromShareX(Map<String, dynamic> json) {
    final requestUrl =
        json['RequestURL'] as String? ?? json['requestURL'] as String?;
    if (requestUrl == null || requestUrl.isEmpty) return null;

    final headersRaw = json['Headers'] ?? json['headers'];
    Map<String, String> headers = {};
    if (headersRaw is Map) {
      for (final e in headersRaw.entries) {
        if (e.value != null) {
          headers[e.key.toString()] = e.value.toString();
        }
      }
    }

    final url = json['URL'] as String? ?? json['url'] as String?;

    return UploadConfig(
      name: json['Name'] as String? ?? json['name'] as String? ?? _domainFromUrl(requestUrl),
      requestUrl: requestUrl,
      requestMethod: json['RequestMethod'] as String? ?? json['requestMethod'] as String? ?? 'POST',
      headers: headers,
      body: json['Body'] as String? ?? json['body'] as String? ?? 'MultipartFormData',
      fileFormName: json['FileFormName'] as String? ?? json['fileFormName'] as String? ?? 'file',
      urlTemplate: url?.trim().isEmpty == true ? null : url,
    );
  }

  static String _domainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return 'Custom uploader';
    }
  }
}
