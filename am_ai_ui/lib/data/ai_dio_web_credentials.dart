import 'package:dio/dio.dart';

import 'ai_dio_web_credentials_stub.dart'
    if (dart.library.html) 'ai_dio_web_credentials_web.dart' as impl;

/// Enable browser cookie credentials for AI gateway calls on web.
void configureAiWebCredentials(Dio dio) => impl.configureAiWebCredentials(dio);
