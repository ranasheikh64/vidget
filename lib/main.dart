import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/storage_service.dart';
import 'app/data/services/network_service.dart';
import 'app/data/services/extractor_service.dart';
import 'app/data/services/download_service.dart';
import 'app/data/services/vault_auth_service.dart';

import 'app/data/services/file_scanner_service.dart';
import 'app/data/services/media_playback_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Storage
  await GetStorage.init();
  
  // Initialize Services
  await initServices();

  runApp(
    GetMaterialApp(
      title: "VidGet",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
    ),
  );
}

Future<void> initServices() async {
  print('starting services ...');
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => NetworkService().init());
  await Get.putAsync(() => DownloadService().init());
  await Get.putAsync(() => FileScannerService().init());
  await Get.putAsync(() => MediaPlaybackService().init());
  Get.put(ExtractorService());
  Get.put(VaultAuthService());
  print('All services started...');
}
