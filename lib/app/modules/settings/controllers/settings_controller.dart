import 'package:get/get.dart';

class SettingsController extends GetxController {
  final darkMode = true.obs;
  final wifiOnly = true.obs;
  final autoStart = false.obs;
  final notifications = true.obs;
  final adultMode = false.obs;
  final appLock = false.obs;
  final vpn = false.obs;
  final doh = true.obs;
  final concurrent = 4.obs;
  final quality = '1080p'.obs;
  final showQualityPicker = false.obs;
  final showStorageInfo = false.obs;

  final qualities = ["144p", "240p", "360p", "480p", "720p", "1080p", "1440p", "4K"];

  void setQuality(String q) {
    quality.value = q;
    showQualityPicker.value = false;
  }

  void incrementConcurrent() {
    if (concurrent.value < 8) concurrent.value++;
  }

  void decrementConcurrent() {
    if (concurrent.value > 1) concurrent.value--;
  }
}
