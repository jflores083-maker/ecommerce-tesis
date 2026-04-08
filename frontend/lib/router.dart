import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/admin_agregar_screen.dart';
import '../screens/admin_modificar_screen.dart';
import '../screens/admin_eliminar_screen.dart';
import '../screens/admin_personalizacion_screen.dart';
import '../screens/acerca_screen.dart';
import '../screens/contacto_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/drops_screen.dart';
import '../screens/drop_detalle_screen.dart';
import '../screens/admin_drops_screen.dart';
import '../screens/admin_crear_drop_screen.dart';
import '../screens/admin_editar_drop_screen.dart';
import '../screens/admin_codigos_screen.dart';
import '../screens/admin_precios_screen.dart';
import '../screens/admin_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Rutas que requieren login
      if ((state.matchedLocation == '/carrito' ||
           state.matchedLocation == '/perfil') && !isLoggedIn) {
        return '/login';
      }

      // Panel admin — solo usuarios con rol Admin
      if (state.matchedLocation.startsWith('/admin')) {
        if (!isLoggedIn) return '/login';
        if (authProvider.user?.isAdmin != true) return '/';
      }

      // Si ya está logueado y va a login/register, redirigir a home
      if (isLoggedIn && isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/catalogo',
        builder: (ctx, state) {
          final categoria = state.uri.queryParameters['categoria'];
          return CatalogScreen(categoriaInicial: categoria);
        },
      ),
      GoRoute(
        path: '/producto/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DetailScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/carrito',
        builder: (ctx, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (ctx, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/admin/agregar',
        builder: (ctx, state) => const AdminAgregarScreen(),
      ),
      GoRoute(
        path: '/admin/modificar',
        builder: (ctx, state) => const AdminModificarScreen(),
      ),
      GoRoute(
        path: '/admin/eliminar',
        builder: (ctx, state) => const AdminEliminarScreen(),
      ),
      GoRoute(
        path: '/admin/personalizacion',
        builder: (ctx, state) => const AdminPersonalizacionScreen(),
      ),
      GoRoute(
        path: '/acerca-de',
        builder: (ctx, state) => const AcercaScreen(),
      ),
      GoRoute(
        path: '/contacto',
        builder: (ctx, state) => const ContactoScreen(),
      ),
      GoRoute(
        path: '/perfil',
        builder: (ctx, state) => const PerfilScreen(),
      ),
      GoRoute(
        path: '/drops',
        builder: (ctx, state) => const DropsScreen(),
      ),
      GoRoute(
        path: '/drops/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DropDetalleScreen(dropId: id);
        },
      ),
      GoRoute(
        path: '/admin/drops',
        builder: (ctx, state) => const AdminDropsScreen(),
      ),
      GoRoute(
        path: '/admin/drops/nuevo',
        builder: (ctx, state) => const AdminCrearDropScreen(),
      ),
      GoRoute(
        path: '/admin/drops/:id/editar',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AdminEditarDropScreen(dropId: id);
        },
      ),
      GoRoute(
        path: '/admin/codigos',
        builder: (ctx, state) => const AdminCodigosScreen(),
      ),
      GoRoute(
        path: '/admin/precios',
        builder: (ctx, state) => const AdminPreciosScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (ctx, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
