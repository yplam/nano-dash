import 'package:flutter/foundation.dart' show kIsWeb;

import 'app.dart';
import 'constants.dart';

void main() async {
  await bootstrapApp(flavor: kIsWeb ? AppFlavor.web : AppFlavor.desktop);
}
