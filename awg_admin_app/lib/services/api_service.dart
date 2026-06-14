import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, String>> _headers({bool multipart = false}) async {
    final token = await AuthService.getToken();
    return {
      if (!multipart) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path, [Map<String, dynamic>? params]) {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    if (params != null) {
      return uri.replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    return _send(
      () async => http.get(_uri(path, params), headers: await _headers()),
    );
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return _send(
      () async => http.post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    return _send(
      () async => http.put(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  static Future<dynamic> delete(String path) async {
    return _send(() async => http.delete(_uri(path), headers: await _headers()));
  }

  static Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      request.headers.addAll(await _headers(multipart: true));
      request.fields.addAll(fields);
      request.files.addAll(files);
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw ApiException(e.message);
    } on FormatException {
      throw ApiException('The server returned an invalid response.');
    } catch (e) {
      throw ApiException('Unable to reach the server. Check your connection.');
    }
  }

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request();
      return _handle(res);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw ApiException(e.message);
    } on FormatException {
      throw ApiException('The server returned an invalid response.');
    } catch (e) {
      throw ApiException('Unable to reach the server. Check your connection.');
    }
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode == 401) {
      AuthService.clearToken();
      throw ApiException('Unauthorized', statusCode: 401);
    }
    final text = utf8.decode(res.bodyBytes).trim();
    final body = text.isEmpty ? null : jsonDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    if (body is Map<String, dynamic>) {
      final error = body['error']?.toString();
      final details = body['details']?.toString();
      throw ApiException(
        details != null && details.isNotEmpty && details != error
            ? '${error ?? 'Request failed'}: $details'
            : error ?? body['message']?.toString() ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
    throw ApiException(
      text.isNotEmpty ? text : 'Request failed',
      statusCode: res.statusCode,
    );
  }
}
