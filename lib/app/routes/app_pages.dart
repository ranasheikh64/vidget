import 'package:get/get.dart';
import '../modules/main_nav/bindings/main_nav_binding.dart';
import '../modules/main_nav/views/main_nav_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/downloads/bindings/downloads_binding.dart';
import '../modules/downloads/views/downloads_view.dart';
import '../modules/browser/bindings/browser_binding.dart';
import '../modules/browser/views/browser_view.dart';
import '../modules/files/bindings/files_binding.dart';
import '../modules/files/views/files_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/vault/bindings/vault_binding.dart';
import '../modules/vault/views/vault_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.MAIN;

  static final routes = [
    GetPage(
      name: _Paths.MAIN,
      page: () => const MainNavigationView(),
      binding: MainNavBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.DOWNLOADS,
      page: () => const DownloadsView(),
      binding: DownloadsBinding(),
    ),
    GetPage(
      name: _Paths.BROWSER,
      page: () => const BrowserView(),
      binding: BrowserBinding(),
    ),
    GetPage(
      name: _Paths.FILES,
      page: () => const FilesView(),
      binding: FilesBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.VAULT,
      page: () => const VaultView(),
      binding: VaultBinding(),
    ),
    
  ];
}

abstract class _Paths {
  _Paths._();
  static const MAIN = Routes.MAIN;
  static const HOME = Routes.HOME;
  static const DOWNLOADS = Routes.DOWNLOADS;
  static const BROWSER = Routes.BROWSER;
  static const FILES = Routes.FILES;
  static const SETTINGS = Routes.SETTINGS;
  static const VAULT = Routes.VAULT;
}
