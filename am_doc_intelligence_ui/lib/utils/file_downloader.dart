// Conditionally export the appropriate implementation
export 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';
