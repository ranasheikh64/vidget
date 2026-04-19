import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vidget/app/data/models/vault_file_model.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/vault_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class VaultView extends GetView<VaultController> {
  const VaultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgVault,
      body: SafeArea(
        child: Obx(() {
          if (!controller.unlocked.value) return _buildPinEntry();
          if (controller.isVaultBrowsing.value) return _buildVaultBrowser();
          return _buildVaultContent();
        }),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Column(
      children: [
        _buildHeader(onBack: () => Get.back()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.violet.withOpacity(0.3)),
                  ),
                  child: const Icon(LucideIcons.lock, size: 28, color: AppColors.violetLight),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  controller.isSetupMode.value 
                    ? (controller.setupStep.value == 1 ? "Set Vault PIN" : "Confirm PIN")
                    : "Enter Vault PIN", 
                  style: AppTextStyles.h2
                ),
                const SizedBox(height: 8),
                Text(
                  controller.isSetupMode.value
                    ? "Choose a 4-digit code to protect your files"
                    : "Your files are encrypted with AES-256", 
                  style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)
                ),
                const SizedBox(height: 32),
                _buildPinDots(),
                const SizedBox(height: 16),
                if (controller.error.value)
                  Text(
                    controller.isSetupMode.value ? "PINs do not match. Restarting..." : "Incorrect PIN. Try again.", 
                    style: AppTextStyles.micro.copyWith(color: AppColors.red)
                  ).animate().shake(),
                const SizedBox(height: 32),
                _buildKeypad(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required VoidCallback onBack}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.chevronLeft, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text("Private Vault", style: AppTextStyles.h2),
            ],
          ),
          Row(
            children: [
              const Icon(LucideIcons.shield, size: 14, color: AppColors.violetLight),
              const SizedBox(width: 6),
              Text("AES-256", style: AppTextStyles.caption.copyWith(color: AppColors.violetLight, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isActive = controller.pin.value.length > i;
        final isError = controller.error.value;
        return AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isError ? AppColors.red.withOpacity(0.4) : (isActive ? AppColors.violet : Colors.transparent),
            border: Border.all(color: isError ? AppColors.red : (isActive ? AppColors.violet : AppColors.gray), width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      ["bio", "0", "del"],
    ];

    return Column(
      children: keys.map((row) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.map((key) => _keyButton(key)).toList(),
      )).toList(),
    );
  }

  Widget _keyButton(String key) {
    bool isSpecial = key == "bio" || key == "del";
    return GestureDetector(
      onTap: () {
        if (key == "bio") {
          controller.authenticateWithBiometrics();
        } else {
          controller.handleKey(key);
        }
      },
      child: Container(
        width: 70,
        height: 56,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSpecial ? Colors.white.withOpacity(0.05) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: isSpecial ? null : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        alignment: Alignment.center,
        child: key == "bio"
            ? const Icon(LucideIcons.fingerprint, size: 24, color: AppColors.violetLight)
            : key == "del"
                ? const Text("⌫", style: TextStyle(color: AppColors.textSecondary, fontSize: 18))
                : Text(key, style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.normal)),
      ),
    );
  }

  Widget _buildVaultBrowser() {
    return Column(
      children: [
        // Secure Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Obx(() => controller.canGoBack.value
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      onPressed: () => controller.vaultBrowserBack(),
                      icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Colors.white70),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  )
                : const SizedBox.shrink()
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text("SECURE SESSION", style: AppTextStyles.nano.copyWith(color: AppColors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      controller.activeVaultUrl.value,
                      style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => controller.closeVaultBrowser(),
                icon: const Icon(LucideIcons.power, size: 16),
                label: const Text("EXIT & WIPE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red.withOpacity(0.2),
                  foregroundColor: AppColors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        // Browser Window
        Expanded(
          child: Stack(
            children: [
              if (controller.vaultWebViewController != null)
                Stack(
                  children: [
                    WebViewWidget(controller: controller.vaultWebViewController!),
                    
                    // SECURE DOWNLOAD Button Removed for stealth mode
                    const SizedBox.shrink(),

                    // Download Progress Overlay
                    Obx(() => controller.isDownloading.value
                      ? Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.violet.withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.shieldCheck, size: 48, color: AppColors.violetLight),
                                  const SizedBox(height: 16),
                                  Text("Encrypting & Saving...", style: AppTextStyles.h3),
                                  const SizedBox(height: 24),
                                  LinearProgressIndicator(
                                    value: controller.downloadProgress.value,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation(AppColors.violet),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${(controller.downloadProgress.value * 100).toInt()}% Securely Cached",
                                    style: AppTextStyles.label,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()
                    ),
                  ],
                ),
              
              if (controller.isLoading.value)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.violet,
                  minHeight: 2,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaultContent() {
    return Column(
      children: [
        _buildHeader(onBack: () => controller.lock()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildStatusAlert(),
              const SizedBox(height: 16),
              Text("ENCRYPTED FILES", style: AppTextStyles.label),
              const SizedBox(height: 12),
              ...controller.vaultFiles.map((file) => _buildFileItem(file)),
              const SizedBox(height: 24),
              Text("PRIVATE SITES", style: AppTextStyles.label),
              const SizedBox(height: 12),
              _buildAdultSitesGrid(),
              const SizedBox(height: 24),
              Text("VAULT STATS", style: AppTextStyles.label),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildLockButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.green.withOpacity(0.2))),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms, curve: Curves.easeInOut),
          const SizedBox(width: 12),
          Text("Vault unlocked • Auto-locks in 5 min", style: AppTextStyles.micro.copyWith(color: AppColors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFileItem(VaultFile file) {
    return GestureDetector(
      onTap: () => controller.openVaultFile(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.violet.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(file.thumb, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  Text("${file.size} • Encrypted", style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            const Icon(LucideIcons.lock, size: 14, color: AppColors.violetLight),
          ],
        ),
      ),
    );
  }

  Widget _buildAdultSitesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: controller.adultSites.length,
      itemBuilder: (context, index) {
        final site = controller.adultSites[index];
        return GestureDetector(
          onTap: () => controller.visitSite(site['url']!),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(site['icon']!, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 8),
              Text(
                site['name']!,
                style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'label': 'Total Files', 'value': '4'},
      {'label': 'Storage Used', 'value': '562 MB'},
      {'label': 'Encryption', 'value': 'AES-256'},
      {'label': 'Key Storage', 'value': 'Keystore'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s['label']!, style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
              Text(s['value']!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockButton() {
    return InkWell(
      onTap: () => controller.lock(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.lock, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text("Lock Vault", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
