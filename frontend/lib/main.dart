import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/carrito_provider.dart';
import 'providers/config_provider.dart';
import 'providers/drops_provider.dart';
import 'providers/productos_provider.dart';
import 'services/api_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const App638());
}

class App638 extends StatelessWidget {
  const App638({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CarritoProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductosProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ConfigProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => DropsProvider(apiService),
        ),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late final _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = createRouter(auth);

    // Cargar configuración de la tienda (hero + tema)
    context.read<ConfigProvider>().cargarConfig();

    // Cuando el usuario hace login, cargar el carrito
    auth.addListener(() {
      if (auth.isLoggedIn) {
        context.read<CarritoProvider>().cargarCarrito();
      } else {
        context.read<CarritoProvider>().limpiarLocal();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.watch<ConfigProvider>().paleta;
    return MaterialApp.router(
      title: '638',
      theme: AppTheme.forPaleta(paleta),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
