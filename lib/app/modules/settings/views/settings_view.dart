import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_toggle.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildProCard(),
                      _buildSection("Appearance", [
                        _settingItem(
                          icon: LucideIcons.moon,
                          label: "Dark Mode",
                          sublabel: "Dark theme active",
                          iconBg: AppColors.iconBgViolet,
                          iconColor: AppColors.violetLight,
                          right: Obx(() => CustomToggle(value: controller.darkMode.value, onChanged: (v) => controller.darkMode.value = v)),
                        ),
                        _settingItem(icon: LucideIcons.globe, label: "App Language", sublabel: "English", iconBg: AppColors.iconBgBlue, iconColor: AppColors.blue),
                        _settingItem(icon: LucideIcons.volume2, label: "Content Language", sublabel: "English, Hindi, Bengali", iconBg: AppColors.iconBgGreen, iconColor: AppColors.green),
                      ]),
                      _buildSection("Downloads", [
                        _settingItem(
                          icon: LucideIcons.sliders,
                          label: "Default Quality",
                          sublabel: controller.quality.value,
                          iconBg: AppColors.iconBgViolet,
                          iconColor: AppColors.violetLight,
                          onTap: () => controller.showQualityPicker.value = true,
                        ),
                        _settingItem(
                          icon: LucideIcons.download,
                          label: "Concurrent Downloads",
                          sublabel: "${controller.concurrent.value} at a time",
                          iconBg: AppColors.iconBgBlue,
                          iconColor: AppColors.blue,
                          right: Row(
                            children: [
                              _counterButton("-", onTap: () => controller.decrementConcurrent()),
                              const SizedBox(width: 8),
                              Obx(() => Text("${controller.concurrent.value}", style: AppTextStyles.body.copyWith(color: AppColors.violetLight, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 8),
                              _counterButton("+", onTap: () => controller.incrementConcurrent()),
                            ],
                          ),
                        ),
                        _settingItem(
                          icon: LucideIcons.refreshCw,
                          label: "Auto-Start Downloads",
                          sublabel: "Skip confirmation prompt",
                          iconBg: AppColors.iconBgAmber,
                          iconColor: AppColors.amber,
                          right: Obx(() => CustomToggle(value: controller.autoStart.value, onChanged: (v) => controller.autoStart.value = v, activeColor: AppColors.amber)),
                        ),
                      ]),
                      _buildSection("Network", [
                        _settingItem(
                          icon: LucideIcons.wifi,
                          label: "Wi-Fi Only",
                          sublabel: "Pause on mobile data",
                          iconBg: AppColors.iconBgBlue,
                          iconColor: AppColors.blue,
                          right: Obx(() => CustomToggle(value: controller.wifiOnly.value, onChanged: (v) => controller.wifiOnly.value = v, activeColor: AppColors.blue)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            _buildQualityPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text("Settings", style: AppTextStyles.h1),
    );
  }

  Widget _buildProCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        gradient: LinearGradient(
          colors: [AppColors.violet.withOpacity(0.2), AppColors.blue.withOpacity(0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(gradient: AppColors.primaryGradientDiag, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text("⚡", style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("VidGet Pro", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                Text("v2.4.1 • All features unlocked", style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.violet.withOpacity(0.4))),
            child: Text("Manage", style: AppTextStyles.micro.copyWith(color: AppColors.violetLight, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
          child: Text(title.toUpperCase(), style: AppTextStyles.label),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderSubtle)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _settingItem({required IconData icon, required String label, String? sublabel, Color? iconBg, Color? iconColor, Widget? right, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg ?? Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  if (sublabel != null) Text(sublabel, style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            right ?? const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQualityPicker() {
    return Obx(() => controller.showQualityPicker.value
        ? GestureDetector(
            onTap: () => controller.showQualityPicker.value = false,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Text("Default Quality", style: AppTextStyles.h2),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: controller.qualities.map((q) {
                        final isActive = q == controller.quality.value;
                        return InkWell(
                          onTap: () => controller.setQuality(q),
                          child: Container(
                            width: (Get.width - 60) / 4,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.violet.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? AppColors.violet.withOpacity(0.4) : AppColors.borderSubtle),
                            ),
                            alignment: Alignment.center,
                            child: Text(q, style: AppTextStyles.micro.copyWith(color: isActive ? AppColors.violetLight : AppColors.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => controller.showQualityPicker.value = false,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Cancel"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink());
  }
}
