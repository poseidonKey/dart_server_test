import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_multipart/multipart.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..post('/upload', _uploadHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _uploadHandler(Request request) async {
  if (!request.isMultipart) {
    return Response.badRequest(body: 'bad request');
  }

  await for (final part in request.parts) {
    final headers = part.headers['content-disposition'] ?? '';
    if (headers.contains('name="file"')) {
      final content = await part.readBytes();
      File file = await File('static/image.png').create();
      file.writeAsBytesSync(content);
    }
  }

  return Response.ok('ok\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
