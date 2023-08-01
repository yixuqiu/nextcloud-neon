import 'dart:convert';
import 'dart:typed_data';

import 'package:dynamite_runtime/http_client.dart';
import 'package:nextcloud/src/webdav/props.dart';
import 'package:nextcloud/src/webdav/webdav.dart';
import 'package:universal_io/io.dart';
import 'package:xml/xml.dart' as xml;

/// Base path used on the server
const String webdavBasePath = '/remote.php/webdav';

/// WebDavClient class
class WebDavClient {
  // ignore: public_member_api_docs
  WebDavClient(this.rootClient);

  // ignore: public_member_api_docs
  final DynamiteClient rootClient;

  Future<HttpClientResponse> _send(
    final String method,
    final String url,
    final List<int> expectedCodes, {
    final Stream<Uint8List>? data,
    final Map<String, String>? headers,
  }) async {
    final request = await HttpClient().openUrl(
      method,
      Uri.parse(url),
    )
      ..followRedirects = false
      ..persistentConnection = true;
    for (final header in {
      HttpHeaders.contentTypeHeader: 'application/xml',
      ...?rootClient.baseHeaders,
      if (headers != null) ...headers,
      if (rootClient.authentications.isNotEmpty) ...rootClient.authentications.first.headers,
    }.entries) {
      request.headers.add(header.key, header.value);
    }

    if (data != null) {
      await request.addStream(data);
    }

    final response = await request.close();

    if (!expectedCodes.contains(response.statusCode)) {
      throw DynamiteApiException(
        response.statusCode,
        response.responseHeaders,
        utf8.decode(await response.bodyBytes),
      );
    }

    return response;
  }

  String _constructPath([final String? path]) => [
        rootClient.baseURL,
        webdavBasePath,
        if (path != null) ...[
          path,
        ],
      ]
          .map((part) {
            while (part.startsWith('/')) {
              part = part.substring(1);
            }
            while (part.endsWith('/')) {
              part = part.substring(0, part.length - 1); // coverage:ignore-line
            }
            return part;
          })
          .where((final part) => part.isNotEmpty)
          .join('/');

  Future<WebDavMultistatus> _parseResponse(final HttpClientResponse response) async =>
      WebDavMultistatus.fromXmlElement(xml.XmlDocument.parse(await response.body).rootElement);

  Map<String, String>? _getUploadHeaders({
    required final DateTime? lastModified,
    required final DateTime? created,
    required final int? contentLength,
  }) {
    final headers = <String, String>{
      if (lastModified != null) ...{
        'X-OC-Mtime': (lastModified.millisecondsSinceEpoch ~/ 1000).toString(),
      },
      if (created != null) ...{
        'X-OC-CTime': (created.millisecondsSinceEpoch ~/ 1000).toString(),
      },
      if (contentLength != null) ...{
        'Content-Length': contentLength.toString(),
      },
    };
    return headers.isNotEmpty ? headers : null;
  }

  /// Gets the WebDAV capabilities of the server.
  Future<WebDavOptions> options() async {
    final response = await _send(
      'OPTIONS',
      _constructPath(),
      [200],
    );
    final davCapabilities = response.headers['dav']?.cast<String>().first ?? '';
    final davSearchCapabilities = response.headers['dasl']?.cast<String>().first ?? '';
    return WebDavOptions(
      davCapabilities.split(',').map((final e) => e.trim()).where((final e) => e.isNotEmpty).toSet(),
      davSearchCapabilities.split(',').map((final e) => e.trim()).where((final e) => e.isNotEmpty).toSet(),
    );
  }

  /// Creates a collection at [path].
  ///
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_MKCOL for more information.
  Future<HttpClientResponse> mkcol(
    final String path, {
    final bool safe = true,
  }) async {
    final expectedCodes = [
      201,
      if (safe) ...[
        301,
        405,
      ],
    ];
    return _send(
      'MKCOL',
      _constructPath(path),
      expectedCodes,
    );
  }

  /// Deletes the resource at [path].
  ///
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_DELETE for more information.
  Future<HttpClientResponse> delete(final String path) => _send(
        'DELETE',
        _constructPath(path),
        [204],
      );

  /// Puts a new file at [path] with [localData] as content.
  ///
  /// [lastModified] sets the date when the file was last modified on the server.
  /// [created] sets the date when the file was created on the server.
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_PUT for more information.
  Future<HttpClientResponse> put(
    final Uint8List localData,
    final String path, {
    final DateTime? lastModified,
    final DateTime? created,
  }) =>
      putStream(
        Stream.value(localData),
        path,
        lastModified: lastModified,
        created: created,
        contentLength: localData.lengthInBytes,
      );

  /// Puts a new file at [path] with [localData] as content.
  ///
  /// [lastModified] sets the date when the file was last modified on the server.
  /// [created] sets the date when the file was created on the server.
  /// [contentLength] sets the length of the [localData] that is uploaded.
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_PUT for more information.
  Future<HttpClientResponse> putStream(
    final Stream<Uint8List> localData,
    final String path, {
    final DateTime? lastModified,
    final DateTime? created,
    final int? contentLength,
  }) async =>
      _send(
        'PUT',
        _constructPath(path),
        [200, 201, 204],
        data: localData,
        headers: _getUploadHeaders(
          lastModified: lastModified,
          created: created,
          contentLength: contentLength,
        ),
      );

  /// Gets the content of the file at [path].
  Future<Uint8List> get(final String path) async => (await getStream(path)).bodyBytes;

  /// Gets the content of the file at [path].
  Future<HttpClientResponse> getStream(final String path) async => _send(
        'GET',
        _constructPath(path),
        [200],
      );

  /// Retrieves the props for the resource at [path].
  ///
  /// Optionally populates the given [prop]s on the returned files.
  /// [depth] can be '0', '1' or 'infinity'.
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_PROPFIND for more information.
  Future<WebDavMultistatus> propfind(
    final String path, {
    final WebDavPropfindProp? prop,
    final String? depth,
  }) async {
    assert(depth == null || ['0', '1', 'infinity'].contains(depth), 'Depth has to be 0, 1 or infinity');
    final response = await _send(
      'PROPFIND',
      _constructPath(path),
      [207, 301],
      data: Stream.value(
        Uint8List.fromList(
          utf8.encode(
            WebDavPropfind(prop: prop ?? WebDavPropfindProp()).toXmlElement(namespaces: namespaces).toXmlString(),
          ),
        ),
      ),
      headers: {
        if (depth != null) ...{
          'Depth': depth,
        },
      },
    );
    if (response.statusCode == 301) {
      // coverage:ignore-start
      return propfind(
        response.headers['location']!.first,
        prop: prop,
        depth: depth,
      );
      // coverage:ignore-end
    }
    return _parseResponse(response);
  }

  /// Runs the filter-files report with the [filterRules] on the resource at [path].
  ///
  /// Optionally populates the [prop]s on the returned files.
  /// See https://github.com/owncloud/docs/issues/359 for more information.
  Future<WebDavMultistatus> report(
    final String path,
    final WebDavOcFilterRules filterRules, {
    final WebDavPropfindProp? prop,
  }) async =>
      _parseResponse(
        await _send(
          'REPORT',
          _constructPath(path),
          [200, 207],
          data: Stream.value(
            Uint8List.fromList(
              utf8.encode(
                WebDavOcFilterFiles(
                  filterRules: filterRules,
                  prop: prop ?? WebDavPropfindProp(), // coverage:ignore-line
                ).toXmlElement(namespaces: namespaces).toXmlString(),
              ),
            ),
          ),
        ),
      );

  /// Updates the props of the resource at [path].
  ///
  /// Returns true if the update was successful.
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_PROPPATCH for more information.
  Future<bool> proppatch(
    final String path,
    final WebDavProp prop,
  ) async {
    final response = await _send(
      'PROPPATCH',
      _constructPath(path),
      [200, 207],
      data: Stream.value(
        Uint8List.fromList(
          utf8.encode(
            WebDavPropertyupdate(set: WebDavSet(prop: prop)).toXmlElement(namespaces: namespaces).toXmlString(),
          ),
        ),
      ),
    );
    final data = await _parseResponse(response);
    for (final a in data.responses) {
      for (final b in a.propstats) {
        if (!b.status.contains('200')) {
          return false;
        }
      }
    }
    return true;
  }

  /// Moves the resource from [sourcePath] to [destinationPath].
  ///
  /// If [overwrite] is set any existing resource will be replaced.
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_MOVE for more information.
  Future<HttpClientResponse> move(
    final String sourcePath,
    final String destinationPath, {
    final bool overwrite = false,
  }) =>
      _send(
        'MOVE',
        _constructPath(sourcePath),
        [200, 201, 204],
        headers: {
          'Destination': _constructPath(destinationPath),
          'Overwrite': overwrite ? 'T' : 'F',
        },
      );

  /// Copies the resource from [sourcePath] to [destinationPath].
  ///
  /// If [overwrite] is set any existing resource will be replaced.
  /// See http://www.webdav.org/specs/rfc2518.html#METHOD_COPY for more information.
  Future<HttpClientResponse> copy(
    final String sourcePath,
    final String destinationPath, {
    final bool overwrite = false,
  }) =>
      _send(
        'COPY',
        _constructPath(sourcePath),
        [200, 201, 204],
        headers: {
          'Destination': _constructPath(destinationPath),
          'Overwrite': overwrite ? 'T' : 'F',
        },
      );
}

/// WebDAV capabilities
class WebDavOptions {
  /// Creates a new WebDavStatus.
  WebDavOptions(
    this.capabilities,
    this.searchCapabilities,
  );

  /// DAV capabilities as advertised by the server in the 'dav' header.
  Set<String> capabilities;

  /// DAV search and locating capabilities as advertised by the server in the 'dasl' header.
  Set<String> searchCapabilities;
}
