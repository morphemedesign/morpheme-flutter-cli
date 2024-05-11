import 'dart:io';

class HttpClientHelper {
  static Future<List<int>> downloadFile(
    String url, {
    Function(
      int downloadedLength,
      int contentLength,
      double progress,
    )? onProgress,
  }) async {
    var client = HttpClient();
    try {
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = <int>[];
        var contentLength = response.contentLength;
        var downloadedLength = 0;
        await for (var part in response) {
          bytes.addAll(part);
          downloadedLength += part.length;
          if (onProgress != null && contentLength > 0) {
            onProgress(
              downloadedLength,
              contentLength,
              (downloadedLength / contentLength) * 100,
            );
          }
        }
        return bytes;
      } else {
        throw HttpException('Failed to download file from $url');
      }
    } finally {
      client.close();
    }
  }
}
