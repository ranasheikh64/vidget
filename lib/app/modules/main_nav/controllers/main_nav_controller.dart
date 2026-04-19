import 'package:get/get.dart';
import '../../home/views/home_view.dart';
import '../../downloads/views/downloads_view.dart';
import '../../browser/views/browser_view.dart';
import '../../files/views/files_view.dart';
import '../../settings/views/settings_view.dart';

class MainNavController extends GetxController {
  final currentIndex = 0.obs;

  final pages = [
    const HomeView(),
    const DownloadsView(),
    const BrowserView(),
    const FilesView(),
    const SettingsView(),
  ];

  void changePage(int index) {
    currentIndex.value = index;
    // Bindings for each sub-page are handled by GetX when navigated via indexed stack
    // or we can manually initialize them here if needed.
  }
}
