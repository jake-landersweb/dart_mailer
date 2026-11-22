import 'package:shelf/shelf.dart';
import 'response.dart' as response;
import 'envs.dart' as env;

bool isAuthenticated(Map<String, dynamic> headers) =>
    headers['x-api-key'] == env.APIKEY;

Middleware middleware() => (innerHandler) {
      return (request) {
        if (request.url.path != 'health' &&
            !isAuthenticated(request.headers)) {
          return response.auth();
        }
        return innerHandler(request);
      };
    };
