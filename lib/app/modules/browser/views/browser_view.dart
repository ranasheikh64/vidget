import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vidget/app/core/widgets/app_gradient_button.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/browser_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BrowserView extends GetView<BrowserController> {
  const BrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(),
                _buildSubToolbar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
            _buildTabOverlay(),
            _buildBookmarkOverlay(),
            _buildSuggestionOverlay(),
            _buildDetectedMediaFab(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: controller.isPrivate.value ? const Color(0xFF1a0a2e) : AppColors.bg,
          border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            _toolbarIconButton(LucideIcons.home, onTap: () => controller.goHome()),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.showSuggestions.value = true,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isPrivate.value ? LucideIcons.shield : LucideIcons.globe,
                        size: 14, 
                        color: controller.isPrivate.value ? AppColors.violetLight : AppColors.textTertiary
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          controller.urlInput.value.isEmpty ? "Search or enter URL" : _formatUrl(controller.urlInput.value),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: controller.urlInput.value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller.isLoading.value)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.violet)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _toolbarIconButton(LucideIcons.refreshCw, size: 14, onTap: () => controller.activeTab?.controller?.reload()),
          ],
        ),
      );
    });
  }

  String _formatUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (_) {
      return url;
    }
  }

  Widget _toolbarIconButton(IconData icon, {double size = 18, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: size, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSubToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _navButton(LucideIcons.chevronLeft, onTap: () => controller.activeTab?.controller?.goBack()),
          const SizedBox(width: 8),
          _navButton(LucideIcons.chevronRight, onTap: () => controller.activeTab?.controller?.goForward()),
          const Spacer(),
          Obx(() => _statusChip(
            controller.isPrivate.value ? LucideIcons.eyeOff : LucideIcons.eye,
            label: controller.isPrivate.value ? "Private" : "Public",
            isActive: controller.isPrivate.value,
            onTap: () => controller.isPrivate.toggle(),
          )),
          const SizedBox(width: 8),
          _tabCounter(),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _statusChip(IconData icon, {required String label, required bool isActive, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.violet.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppColors.violet.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isActive ? AppColors.violetLight : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.nano.copyWith(color: isActive ? AppColors.violetLight : AppColors.textTertiary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _tabCounter() {
    return GestureDetector(
      onTap: () => controller.showTabs.value = true,
      child: Obx(() => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textSecondary, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          "${controller.tabs.length}",
          style: AppTextStyles.nano.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      )),
    );
  }

  Widget _buildMainContent() {
    return Obx(() {
      final tab = controller.activeTab;
      if (tab == null) return const SizedBox.shrink();

      return Stack(
        children: [
          // The WebView
          Offstage(
            offstage: tab.isHome.value,
            child: WebViewWidget(controller: tab.controller!),
          ),
          
          // Custom Start Page
          if (tab.isHome.value) _buildStartPage(),
        ],
      );
    });
  }

  Widget _buildStartPage() {
    return Container(
      width: double.infinity,
      color: AppColors.bg,
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Branded Logo/Header
          Hero(
            tag: 'browser_logo',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradientDiag,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.violet.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
                ],
              ),
              child: const Icon(LucideIcons.globe, size: 40, color: Colors.white),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          const SizedBox(height: 24),
          Text(
            "VidGet Browser",
            style: AppTextStyles.h1.copyWith(letterSpacing: 1.2),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            "Fast • Secure • Private",
            style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary, letterSpacing: 2),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 48),
          
          // Bookmarks Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: controller.bookmarks.map((b) => _buildBookmarkIcon(b)).toList(),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
          
          const Spacer(flex: 3),
          
          // Privacy Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.green),
                const SizedBox(width: 8),
                Text("Your browsing history is never tracked", style: AppTextStyles.nano.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBookmarkIcon(Map<String, String> bookmark) {
    final color = Color(int.parse(bookmark['color']!.replaceAll('#', '0xFF')));
    return GestureDetector(
      onTap: () => controller.navigateTo(bookmark['url']!, bookmark['name']!, bookmark['favicon']!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(bookmark['favicon']!, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            bookmark['name']!,
            style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedMediaFab() {
    return Obx(() {
      final tab = controller.activeTab;
      if (tab == null || tab.isHome.value) return const SizedBox.shrink();
      
      return controller.detectedMedia.value && !controller.showSuggestions.value
          ? Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: GestureDetector(
                onTap: () => controller.handleMediaAction(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradientDiag,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.playCircle, size: 20, color: Colors.white),
                      const SizedBox(width: 12),
                      Text("Play Detected Video", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutBack).fade(),
              ),
            )
          : const SizedBox.shrink();
    });
  }

  Widget _buildTabOverlay() {
    return Obx(() => controller.showTabs.value
        ? Container(
            color: Colors.black.withOpacity(0.85),
            child: BackdropFilter(
              filter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Opened Tabs", style: AppTextStyles.h2),
                        IconButton(
                          onPressed: () => controller.showTabs.value = false,
                          icon: const Icon(LucideIcons.x, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: controller.tabs.length,
                      itemBuilder: (context, index) {
                        final t = controller.tabs[index];
                        final isActive = t.id == controller.activeTabId.value;
                        return GestureDetector(
                          onTap: () {
                            controller.activeTabId.value = t.id;
                            controller.showTabs.value = false;
                            controller.urlInput.value = t.url.value;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isActive ? AppColors.violet : AppColors.borderSubtle, width: 2),
                              boxShadow: isActive ? [BoxShadow(color: AppColors.violet.withOpacity(0.3), blurRadius: 15)] : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.white.withOpacity(0.03),
                                    alignment: Alignment.center,
                                    child: Text(t.favicon.value, style: const TextStyle(fontSize: 40)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  color: Colors.white.withOpacity(0.05),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.title.value,
                                          style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => controller.closeTab(t.id),
                                        child: const Icon(LucideIcons.x, size: 14, color: AppColors.textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: AppGradientButton(
                      onTap: () => controller.addNewTab(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.plus, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("New Tab", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ).animate().fade()
        : const SizedBox.shrink());
  }

  Widget _buildBookmarkOverlay() {
    return Obx(() => controller.showBookmarks.value
        ? GestureDetector(
            onTap: () => controller.showBookmarks.value = false,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 480,
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.star, size: 20, color: AppColors.violetLight),
                            const SizedBox(width: 12),
                            Text("Fast Access", style: AppTextStyles.h2),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 20),
                            itemCount: controller.bookmarks.length,
                            itemBuilder: (context, index) {
                              final b = controller.bookmarks[index];
                              return _buildBookmarkIcon(b);
                            },
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutQuart),
                ],
              ),
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildSuggestionOverlay() {
    return Obx(() => controller.showSuggestions.value
        ? Container(
            color: AppColors.bg.withOpacity(0.98),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _toolbarIconButton(LucideIcons.globe),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: "Search or enter URL", 
                            border: InputBorder.none, 
                            enabledBorder: InputBorder.none, 
                            focusedBorder: InputBorder.none, 
                            fillColor: Colors.transparent,
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                          ),
                          style: AppTextStyles.body,
                          onSubmitted: (v) => controller.navigateTo(v, v, "🌐"),
                        ),
                      ),
                      GestureDetector(onTap: () => controller.showSuggestions.value = false, child: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle),
                // Recent Bookmark suggestions
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text("SUGGESTIONS", style: AppTextStyles.label.copyWith(letterSpacing: 1)),
                      const SizedBox(height: 16),
                      ...controller.bookmarks.map((b) => ListTile(
                        onTap: () => controller.navigateTo(b['url']!, b['name']!, b['favicon']!),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(b['favicon']!, style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(b['name']!, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(b['url']!.replaceFirst('https://', ''), style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
                        trailing: const Icon(LucideIcons.arrowUpLeft, size: 14, color: AppColors.textTertiary),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade()
        : const SizedBox.shrink());
  }
}
