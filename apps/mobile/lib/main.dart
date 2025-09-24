import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_store.dart';
import 'routing/app_router.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = await AuthStore.create();
  runApp(App(authStore: authStore));
}

class App extends StatelessWidget {
  final AuthStore authStore;
  const App({super.key, required this.authStore});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authStore,
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Vision 2.0',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: buildRouter(context.read<AuthStore>()),
        ),
      ),
    );
  }
}

