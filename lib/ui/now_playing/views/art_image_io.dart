/// `dart:io` art resolver: supports `file://` (local thumbnails) and network
/// URLs. Used on all desktop builds.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider? artImageProvider(Uri? uri) {
  if (uri == null) return null;
  switch (uri.scheme) {
    case 'file':
      return FileImage(File(uri.toFilePath()));
    case 'http':
    case 'https':
      return NetworkImage(uri.toString());
    default:
      // data:/embedded and unknown schemes: no art rather than a broken box.
      return null;
  }
}
