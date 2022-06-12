import 'package:shelf/shelf.dart';
import 'logger.dart' as logger;
import 'response.dart' as response;

import 'envs.dart' as env;

bool isAuthenticated(Map<String, dynamic> headers) {
  if (!headers.containsKey("x-api-key")) {
    return false;
  } else if (headers['x-api-key'] == env.APIKEY) {
    return true;
  } else {
    return false;
  }
}

Middleware middleware() => (innerHandler) {
      return (request) {
        return Future.sync(() => innerHandler(request)).then((r) {
          if (!isAuthenticated(request.headers)) {
            return response.auth();
          }
          return r;
        }, onError: (Object err, StackTrace stackTrace) {
          if (err is HijackException) throw err;
          logger.error("There was an error: $err");
          throw err;
        });
      };
    };
