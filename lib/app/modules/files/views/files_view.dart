import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/files_controller.dart';
import '../../../data/services/file_scanner_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class FilesView extends GetView<FilesController> {
  const FilesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => controller.refreshFiles(),
          color: AppColors.violet,
          backgroundColor: AppColors.bgCard,
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryCards(),
              _buildSearchBar(),
              Obx(() => controller.isScanning 
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.transparent, 
                    color: AppColors.violet,
                    minHeight: 2,
                  ) 
                : const SizedBox(height: 2)),
              Expanded(child: _buildFileList()),
            ],
          ),
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
          Obx(
            () => Text(
              controller.isSelecting
                  ? "${controller.selectedPaths.length} selected"
                  : "Files",
              style: AppTextStyles.h1,
            ),
          ),
          Row(
            children: [
              Obx(
                () => controller.isSelecting
                    ? Row(
                        children: [
                          _actionIcon(
                            LucideIcons.x,
                            onTap: () => controller.clearSelection(),
                          ),
                          const SizedBox(width: 8),
                          _actionIcon(LucideIcons.trash2, color: AppColors.red),
                          const SizedBox(width: 8),
                          _actionIcon(LucideIcons.share2),
                        ],
                      )
                    : Row(
                        children: [
                          _actionIcon(
                            LucideIcons.refreshCcw,
                            onTap: () => controller.refreshFiles(),
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () => _actionIcon(
                              controller.viewMode.value == 'list'
                                  ? LucideIcons.grid
                                  : LucideIcons.list,
                              onTap: () => controller.viewMode.value =
                                  controller.viewMode.value == 'list'
                                  ? 'grid'
                                  : 'list',
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
      ),
    );
  }

  Widget _buildCategoryCards() {
    return Obx(() {
      final categories = controller.categories;
      return SizedBox(
        height: 60,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isActive = controller.activeCategory.value == cat['id'];
            final color = cat['color'] as Color;
            return GestureDetector(
              onTap: () => controller.activeCategory.value = cat['id'] as String,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.15) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? color.withOpacity(0.4) : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, size: 14, color: color),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cat['label'] as String,
                          style: AppTextStyles.micro.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          "${cat['count']} items",
                          style: AppTextStyles.nano.copyWith(
                            color: isActive ? color : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: const InputDecoration(
                  hintText: "Search files...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Obx(() {
      final files = controller.filteredFiles;
      if (files.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.folderX, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                controller.isScanning ? "Scanning device..." : "No files found",
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      if (controller.viewMode.value == 'list') {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileListTile(files[index]),
        );
      } else {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileGridCard(files[index]),
        );
      }
    });
  }

  Widget _buildFileListTile(ScannedFile file) {
    return Obx(() {
      final isSelected = controller.isSelected(file.path);
      return GestureDetector(
        onTap: () => controller.isSelecting ? controller.toggleSelect(file.path) : controller.playFile(file),
        onLongPress: () => controller.toggleSelect(file.path),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.violet.withOpacity(0.1) : AppColors.bgCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.violet.withOpacity(0.4) : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              if (controller.isSelecting) ...[
                Icon(
                  isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                  size: 18,
                  color: isSelected ? AppColors.violetLight : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(file.thumb, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${file.sizeStr} • ${DateFormat('MMM dd, yyyy').format(file.modified)}",
                      style: AppTextStyles.nano.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (!controller.isSelecting)
                const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFileGridCard(ScannedFile file) {
    return Obx(() {
      final isSelected = controller.isSelected(file.path);
      return GestureDetector(
        onTap: () => controller.isSelecting ? controller.toggleSelect(file.path) : controller.playFile(file),
        onLongPress: () => controller.toggleSelect(file.path),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.violet.withOpacity(0.1) : AppColors.bgCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.violet.withOpacity(0.4) : AppColors.borderSubtle,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(file.thumb, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                file.name,
                style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                file.sizeStr,
                style: AppTextStyles.nano.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    });
  }
}
