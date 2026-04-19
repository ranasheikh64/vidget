import 'package:get/get.dart';
import 'package:vidget/app/data/services/extractor_service.dart';
import 'package:vidget/app/data/services/vault_auth_service.dart';
import 'package:vidget/app/modules/vault/controllers/vault_controller.dart';

import '../controllers/main_nav_controller.dart';
import '../../global_player/controllers/global_player_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../downloads/controllers/downloads_controller.dart';
import '../../browser/controllers/browser_controller.dart';
import '../../files/controllers/files_controller.dart';
import '../../settings/controllers/settings_controller.dart';

class MainNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavController>(() => MainNavController());

    // We also put the controllers for the sub-pages here to ensure they are available
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<DownloadsController>(() => DownloadsController());
    Get.lazyPut<BrowserController>(() => BrowserController());
    Get.lazyPut<FilesController>(() => FilesController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<VaultController>(() => VaultController());
    Get.put(ExtractorService());
    Get.put(VaultAuthService());
    Get.put(GlobalPlayerController(), permanent: true);
  }
}
