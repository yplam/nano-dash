import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

/// Global [GetIt.instance].
final GetIt locator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  locator.registerSingleton<Logger>(Logger());
}
