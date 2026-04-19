import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/downloads_controller.dart';
import '../../../data/models/download_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DownloadsView extends GetView<DownloadsController> {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            _buildFilters(),
            Expanded(
              child: Obx(() {
                final filtered = controller.allDownloads.where((d) {
                  if (controller.activeFilter.value == 'All') return true;
                  if (controller.activeFilter.value == 'Active') {
                    return d.status == DownloadStatus.downloading || d.status == DownloadStatus.paused || d.status == DownloadStatus.queued;
                  }
                  if (controller.activeFilter.value == 'Completed') return d.status == DownloadStatus.completed;
                  if (controller.activeFilter.value == 'Failed') return d.status == DownloadStatus.failed;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildDownloadCard(filtered[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Downloads", style: AppTextStyles.h1),
          Row(
            children: [
              Obx(() => GestureDetector(
                onTap: () => controller.wifiOnly.toggle(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.wifiOnly.value ? AppColors.violet.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: controller.wifiOnly.value ? AppColors.violet.withOpacity(0.4) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(controller.wifiOnly.value ? LucideIcons.wifi : LucideIcons.wifiOff, size: 12, color: controller.wifiOnly.value ? AppColors.violetLight : AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(controller.wifiOnly.value ? "Wi-Fi" : "Data", style: AppTextStyles.micro.copyWith(color: controller.wifiOnly.value ? AppColors.violetLight : AppColors.textTertiary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                child: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("Active", controller.activeCount.toString(), AppColors.violetLight),
          _buildDivider(),
          _buildStat("Done", controller.completedCount.toString(), AppColors.green),
          _buildDivider(),
          _buildStat("MB/s", "6.4", Colors.white),
        ],
      )),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h1.copyWith(color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: AppColors.borderSubtle);
  }

  Widget _buildFilters() {
    final filters = ["All", "Active", "Completed", "Failed"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((tab) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Obx(() {
              final isActive = controller.activeFilter.value == tab;
              return GestureDetector(
                onTap: () => controller.activeFilter.value = tab,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.violet : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDownloadCard(DownloadItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(item.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(item.site, style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
                        Container(width: 2, height: 2, decoration: const BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(item.quality, style: AppTextStyles.nano.copyWith(color: AppColors.textSecondary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(item.format, style: AppTextStyles.nano.copyWith(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (item.status == DownloadStatus.downloading || item.status == DownloadStatus.paused)
                    IconButton(
                      icon: Icon(item.status == DownloadStatus.downloading ? LucideIcons.pause : LucideIcons.play, size: 16, color: Colors.white),
                      onPressed: () => controller.togglePause(item.id),
                    ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textTertiary),
                    onPressed: () => controller.removeDownload(item.id),
                  ),
                ],
              ),
            ],
          ),
          if (item.status != DownloadStatus.queued) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _getStatusIcon(item.status),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(item),
                      style: AppTextStyles.micro.copyWith(
                        color: _getStatusColor(item.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text("${item.progress.toInt()}%", style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: item.progress / 100,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(item.status)),
                minHeight: 6,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 10, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text("Queued • ${item.size} • ${item.quality}", style: AppTextStyles.micro.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.download, size: 32, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No downloads here", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text("Paste a URL on the Home tab", style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed: return const Icon(LucideIcons.checkCircle, size: 10, color: AppColors.green);
      case DownloadStatus.failed: return const Icon(LucideIcons.alertCircle, size: 10, color: AppColors.red);
      case DownloadStatus.downloading: return const Icon(LucideIcons.download, size: 10, color: AppColors.violetLight);
      case DownloadStatus.paused: return const Icon(LucideIcons.pause, size: 10, color: AppColors.amber);
      default: return const Icon(LucideIcons.clock, size: 10, color: AppColors.gray);
    }
  }

  String _getStatusText(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading: return "${item.speed} • ${item.eta} left";
      case DownloadStatus.paused: return "Paused";
      case DownloadStatus.completed: return "Completed • ${item.size}";
      case DownloadStatus.failed: return "Failed — tap retry";
      case DownloadStatus.queued: return "Queued";
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed: return AppColors.green;
      case DownloadStatus.failed: return AppColors.red;
      case DownloadStatus.downloading: return AppColors.violet;
      case DownloadStatus.paused: return AppColors.amber;
      default: return AppColors.gray;
    }
  }
}
