import 'package:get/get.dart';
import '../../../data/models/download_item_model.dart';
import '../../../data/services/download_service.dart';

class DownloadsController extends GetxController {
  final _downloadService = Get.find<DownloadService>();

  // Use the service's lists directly or wrap them in Rx lists for UI updates
  RxList<DownloadItem> get allDownloads {
    final list = <DownloadItem>[];
    list.addAll(_downloadService.activeDownloads.values);
    list.addAll(_downloadService.queue);
    list.addAll(_downloadService.completedDownloads);
    list.addAll(_downloadService.failedDownloads);
    return list.obs;
  }

  final activeFilter = 'All'.obs;
  final wifiOnly = true.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void togglePause(int id) {
    // Implement if needed in service
  }

  void removeDownload(int id) {
    _downloadService.activeDownloads.remove(id);
    _downloadService.completedDownloads.removeWhere((d) => d.id == id);
    _downloadService.failedDownloads.removeWhere((d) => d.id == id);
    _downloadService.queue.removeWhere((d) => d.id == id);
  }

  int get activeCount => _downloadService.activeDownloads.length + _downloadService.queue.length;
  int get completedCount => _downloadService.completedDownloads.length;
}
