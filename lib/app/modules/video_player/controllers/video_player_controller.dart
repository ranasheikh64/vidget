import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import '../../../data/models/video_item_model.dart';

class VideoController extends GetxController {
  late PodPlayerController podController;
  final isLoading = true.obs;
  final videoItem = Rxn<VideoItem>();

  @override
  void onInit() {
    super.onInit();
    final item = Get.arguments as VideoItem?;
    if (item != null) {
      videoItem.value = item;
      _initializePlayer(item);
    }
  }

  void _initializePlayer(VideoItem item) async {
    try {
      if (item.videoUrl == null) {
        isLoading.value = false;
        return;
      }

      podController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(item.videoUrl!),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
          videoQualityPriority: [720, 360],
        ),
      )..initialise().then((_) {
        isLoading.value = false;
      });
    } catch (e) {
      print("Player init error: $e");
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    podController.dispose();
    super.onClose();
  }
}
