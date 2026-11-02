import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'store/widgets.dart';
import 'store/api.dart';
import 'store/state.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Noto Sans Tamil'], license);
  });
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final api = StoreApi();
  await api.restoreStaffSession();
  runApp(
    ProviderScope(
      overrides: [storeApiProvider.overrideWithValue(api)],
      child: AgaramSupermarketApp(
        router: createAppRouter(initialLocation: api.staffWorkspace),
      ),
    ),
  );
}

class AgaramSupermarketApp extends StatelessWidget {
  final GoRouter? router;
  const AgaramSupermarketApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AGARAM Supermarket',
      debugShowCheckedModeBanner: false,
      theme: storeTheme(),
      routerConfig: router ?? appRouter,
    );
  }
}
