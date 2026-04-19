import 'dart:io';

import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import '../../../data/models/video_item_model.dart';

class GlobalPlayerController extends GetxController {
  PodPlayerController? podController;
  final isLoading = true.obs;
  final isPlayerVisible = false.obs;
  final isMaximized = true.obs; // Player starts maximized
  final videoItem = Rxn<VideoItem>();
  
  // Player dimensions
  final double miniHeight = 70.0;
  final RxDouble playerHeight = 0.0.obs;

  void playVideo(VideoItem item) async {
    // 1. Reset and hide UI immediately to prevent race conditions during disposal
    isLoading.value = true;
    isPlayerVisible.value = true;
    isMaximized.value = true;
    
    // 2. Safely dispose of old controller
    if (podController != null) {
      final oldController = podController;
      podController = null; // Clear reference before disposing
      update(); // Notify UI to stop using the controller
      await Future.delayed(const Duration(milliseconds: 100));
      oldController!.dispose();
    }

    videoItem.value = item;

    try {
      if (item.videoUrl == null) {
        isLoading.value = false;
        return;
      }

      final url = item.videoUrl!;
      PlayVideoFrom playFrom;

      if (url.startsWith('http')) {
        if (url.contains('youtube.com') || url.contains('youtu.be')) {
          playFrom = PlayVideoFrom.youtube(url);
        } else {
          playFrom = PlayVideoFrom.network(url);
        }
      } else {
        // Assume it's a local file path (Decrypted Vault video)
        playFrom = PlayVideoFrom.file(File(url));
      }

      podController = PodPlayerController(
        playVideoFrom: playFrom,
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
          videoQualityPriority: [720, 480, 360],
          wakelockEnabled: true, // Keep screen on & CPU active for smooth playback
        ),
      )..initialise().then((_) {
        isLoading.value = false;
        // Ensure we pause other activities or notify UI
        update(); 
      });
    } catch (e) {
      print("[GlobalPlayer] Init error: $e");
      isLoading.value = false;
    }
  }

  void toggleMinimize() {
    isMaximized.value = !isMaximized.value;
  }

  void closePlayer() {
    isPlayerVisible.value = false;
    podController?.dispose();
    podController = null;
    videoItem.value = null;
  }

  @override
  void onClose() {
    podController?.dispose();
    super.onClose();
  }
}
