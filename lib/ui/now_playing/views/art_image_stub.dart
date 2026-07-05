/// Web art resolver: network URLs only (`file://` needs `dart:io`, absent on
/// web). The Now Playing module isn't shipped on web, so this exists purely to
/// keep the tree compiling.
library;

import 'package:flutter/widgets.dart';

ImageProvider? artImageProvider(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return NetworkImage(uri.toString());
  }
  return null;
}
