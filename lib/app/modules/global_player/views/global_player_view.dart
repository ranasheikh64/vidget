import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/global_player_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GlobalPlayerView extends GetView<GlobalPlayerController> {
  const GlobalPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isPlayerVisible.value) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuart,
        height: controller.isMaximized.value ? Get.height : controller.miniHeight,
        margin: EdgeInsets.only(
          bottom: controller.isMaximized.value ? 0 : 80, // Above bottom nav
          left: controller.isMaximized.value ? 0 : 12,
          right: controller.isMaximized.value ? 0 : 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(controller.isMaximized.value ? 0 : 16),
          boxShadow: [
            if (!controller.isMaximized.value)
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(controller.isMaximized.value ? 0 : 16),
          child: controller.isMaximized.value ? _buildFullPlayer() : _buildMiniPlayer(),
        ),
      );
    });
  }

  Widget _buildMiniPlayer() {
    final video = controller.videoItem.value;
    return GestureDetector(
      onTap: () => controller.isMaximized.value = true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Thumbnail (Fixed strict clipping to prevent overflows)
            Container(
              width: 60,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: video?.thumb != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: Image.network(
                          video!.thumb,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(width: 60, height: 44),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video?.title ?? "Playing...",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false, // Prevent multi-line layout loops
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      video?.channel ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.nano.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (controller.podController?.isVideoPlaying == true) {
                  controller.podController?.pause();
                } else {
                  controller.podController?.play();
                }
                controller.update();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  controller.podController?.isVideoPlaying == true ? LucideIcons.pause : LucideIcons.play,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => controller.closePlayer(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(LucideIcons.x, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPlayer() {
    final video = controller.videoItem.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header Drag Handle
          GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 10) controller.isMaximized.value = false;
            },
            child: Container(
              height: 40,
              width: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: controller.isLoading.value || controller.podController == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.violet))
                : PodVideoPlayer(
                    controller: controller.podController!,
                    frameAspectRatio: 16/9,
                    videoAspectRatio: 16/9,
                  ),
          ),

          // Details
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: ListView(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video?.title ?? "", style: AppTextStyles.h2),
                            const SizedBox(height: 8),
                            Text("${video?.views} views • ${video?.channel}", 
                                 style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
                        onPressed: () => controller.isMaximized.value = false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionButton(LucideIcons.thumbsUp, "Like"),
                      _actionButton(LucideIcons.share2, "Share"),
                      if (!(video?.videoUrl?.startsWith('http') == false)) 
                        _actionButton(LucideIcons.download, "Download"),
                      _actionButton(LucideIcons.listPlus, "Save"),
                    ],
                  ),
                  const Divider(height: 48, color: AppColors.borderSubtle),
                  // Channel Info
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video?.channel ?? "Channel", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                            Text("1.2M Subscribers", style: AppTextStyles.nano.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("SUBSCRIBE", style: TextStyle(color: AppColors.violetLight, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.nano.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
