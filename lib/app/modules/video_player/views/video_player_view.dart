import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vidget/app/modules/video_player/controllers/video_player_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class VideoPlayerView extends GetView<VideoController> {
  const VideoPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            );
          }

          if (controller.videoItem.value?.videoUrl == null) {
            return _buildErrorState();
          }

          return Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: PodVideoPlayer(
                    controller: controller.podController,
                    frameAspectRatio: 16 / 9,
                    videoAspectRatio: 16 / 9,
                  ),
                ),
              ),
              _buildVideoDetails(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              controller.videoItem.value?.title ?? "Playing Video",
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDetails() {
    final item = controller.videoItem.value!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTextStyles.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(item.channel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.violetLight, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text("${item.views} views", style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(LucideIcons.download, "Download"),
              _actionButton(LucideIcons.share2, "Share"),
              _actionButton(LucideIcons.heart, "Save"),
              _actionButton(LucideIcons.info, "Details"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.nano.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.red, size: 48),
          const SizedBox(height: 16),
          Text("Could not resolve video URL", style: AppTextStyles.body.copyWith(color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.violet),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }
}
