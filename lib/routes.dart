import 'package:routefly/routefly.dart';

import 'app/home/home_page.dart' as a0;
import 'app/login/login_page.dart' as a1;
import 'app/matricula/home_page.dart' as a2;
import 'app/prefs/prefs_page.dart' as a3;

List<RouteEntity> get routes => [
  RouteEntity(
    key: '/home',
    uri: Uri.parse('/home'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a0.HomePage(),
    ),
  ),
  RouteEntity(
    key: '/login',
    uri: Uri.parse('/login'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a1.LoginPage(),
    ),
  ),
  RouteEntity(
    key: '/matricula/home',
    uri: Uri.parse('/matricula/home'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a2.StartPage(),
    ),
  ),
  RouteEntity(
    key: '/prefs',
    uri: Uri.parse('/prefs'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a3.PrefsPage(),
    ),
  ),
];

const routePaths = (
  path: '/',
  home: '/home',
  login: '/login',
  matricula: (
    path: '/matricula',
    home: '/matricula/home',
  ),
  prefs: '/prefs',
);
