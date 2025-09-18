import 'dart:io';

/// Helper class for HTTP client operations.
///
/// This class provides utilities for downloading files over HTTP
/// with progress reporting capabilities.
class HttpClientHelper {
  /// Downloads a file from a URL with optional progress reporting.
  ///
  /// This method downloads a file from the specified URL and returns
  /// the file contents as a list of bytes. It optionally supports
  /// progress reporting through a callback function.
  ///
  /// Parameters:
  /// - [url]: The URL of the file to download
  /// - [onProgress]: Optional callback function to report download progress
  ///   The callback receives three parameters:
  ///   - downloadedLength: Number of bytes downloaded so far
  ///   - contentLength: Total size of the file in bytes (-1 if unknown)
  ///   - progress: Percentage of download completed (0.0 to 100.0)
  ///
  /// Returns: A Future that completes with the downloaded file contents as List<int>
  ///
  /// Example:
  /// ```dart
  /// // Download a file with progress reporting
  /// final bytes = await HttpClientHelper.downloadFile(
  ///   'https://example.com/file.zip',
  ///   onProgress: (downloaded, total, progress) {
  ///     print('Downloaded $downloaded of $total bytes ($progress%)');
  ///   },
  /// );
  /// print('Downloaded ${bytes.length} bytes');
  /// ```
  ///
  /// Throws: HttpException if the download fails
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
        throw HttpException('Failed to download file from $url with status code ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
}