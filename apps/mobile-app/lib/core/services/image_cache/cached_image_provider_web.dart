import 'package:flutter/painting.dart';

/// Web: the browser's HTTP cache persists pictures; nothing extra to do.
ImageProvider<Object> cachedImageProvider(String url) => NetworkImage(url);
