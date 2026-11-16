/// Product / catalog pictures that survive app restarts.
///
/// `Image.network` only keeps pictures in the in-memory [ImageCache], so every
/// cold start re-downloads every product photo — slow and costly on mobile
/// data. [cachedImageProvider] keeps the downloaded bytes on disk (native) and
/// serves them from there afterwards, offline included. On web the browser's
/// own HTTP cache already does this, so it is a plain [NetworkImage].
library;

export 'cached_image_provider_web.dart'
    if (dart.library.io) 'cached_image_provider_io.dart';
