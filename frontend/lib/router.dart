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

      // Si el carrito requiere login y no está autenticado
      if (state.matchedLocation == '/carrito' && !isLoggedIn) {
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
    ],
  );
}
