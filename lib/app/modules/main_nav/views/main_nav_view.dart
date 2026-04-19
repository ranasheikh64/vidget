import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vidget/app/routes/app_routes.dart';
import '../controllers/main_nav_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../global_player/views/global_player_view.dart';
import '../../../data/services/download_service.dart';

class MainNavigationView extends GetView<MainNavController> {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow (Matches React Design)
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.violet.withOpacity(0.1),
                    AppColors.blue.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: controller.pages,
          )),
          
          // Global Media Player Layer
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 0,
            child: GlobalPlayerView(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bg.withOpacity(0.95),
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, LucideIcons.home, "Home"),
                  Obx(() {
                    final service = Get.find<DownloadService>();
                    final count = service.activeDownloads.length + service.queue.length;
                    return _navItem(1, LucideIcons.download, "Downloads", 
                      badge: count > 0 ? count.toString() : null);
                  }),
                  _navItem(2, LucideIcons.globe, "Browser"),
                  _navItem(3, LucideIcons.folderOpen, "Files"),
                  _navItem(4, LucideIcons.settings, "Settings"),
                  _vaultItem(),
                ],
              ),
            ),
            // Home Indicator (Matches iOS/Design look)
            Center(
              child: Container(
                width: 90,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {String? badge}) {
    return Obx(() {
      final isActive = controller.currentIndex.value == index;
      return GestureDetector(
        onTap: () => controller.changePage(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.violet.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isActive ? AppColors.violetLight : AppColors.gray,
                    ),
                    if (badge != null)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.violet,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            badge,
                            style: AppTextStyles.nano.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: isActive ? AppTextStyles.tabActive : AppTextStyles.tabInactive,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _vaultItem() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.VAULT),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.lock,
              size: 20,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Vault",
            style: AppTextStyles.tabInactive,
          ),
        ],
      ),
    );
  }
}
