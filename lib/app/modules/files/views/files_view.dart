import 'dart:io';

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
              _buildHeroBanner(),
              _buildSearchBar(),
              Obx(
                () => controller.isScanning
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: AppColors.violet,
                        minHeight: 2,
                      )
                    : const SizedBox(height: 2),
              ),
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
              onTap: () =>
                  controller.activeCategory.value = cat['id'] as String,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.15) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? color.withOpacity(0.4)
                        : AppColors.borderSubtle,
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
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
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

  Widget _buildHeroBanner() {
    return Obx(() {
      if (controller.featuredFiles.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: controller.featuredFiles.length,
          itemBuilder: (context, index) {
            final file = controller.featuredFiles[index];
            return GestureDetector(
              onTap: () {
                if (file.category == FileCategory.images) {
                  _showImagePreview(context, file);
                } else {
                  controller.playFile(file);
                }

                Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: file.thumbnailPath != null
                        ? DecorationImage(
                            image: FileImage(File(file.thumbnailPath!)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                    color: AppColors.bgCard,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (file.thumbnailPath == null)
                        Center(
                          child: Icon(
                            file.category == FileCategory.videos
                                ? LucideIcons.video
                                : LucideIcons.image,
                            size: 40,
                            color: AppColors.violet.withOpacity(0.5),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                file.name,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                file.sizeStr,
                                style: AppTextStyles.nano.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                file.category == FileCategory.videos
                                    ? LucideIcons.play
                                    : LucideIcons.image,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                file.category == FileCategory.videos
                                    ? "VIDEO"
                                    : "IMAGE",
                                style: AppTextStyles.nano.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
            const Icon(
              LucideIcons.search,
              size: 14,
              color: AppColors.textTertiary,
            ),
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
              const Icon(
                LucideIcons.folderX,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                controller.isScanning ? "Scanning device..." : "No files found",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
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
            childAspectRatio: 0.85,
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
        onTap: () => controller.isSelecting
            ? controller.toggleSelect(file.path)
            : controller.playFile(file),
        onLongPress: () => controller.toggleSelect(file.path),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.violet.withOpacity(0.1)
                : AppColors.bgCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.violet.withOpacity(0.4)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              if (controller.isSelecting) ...[
                Icon(
                  isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                  size: 18,
                  color: isSelected
                      ? AppColors.violetLight
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildThumbnail(file),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${file.sizeStr} • ${DateFormat('MMM dd, yyyy').format(file.modified)}",
                      style: AppTextStyles.nano.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!controller.isSelecting)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
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
        onTap: () => controller.isSelecting
            ? controller.toggleSelect(file.path)
            : controller.playFile(file),
        onLongPress: () => controller.toggleSelect(file.path),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.violet.withOpacity(0.1)
                : AppColors.bgCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.violet.withOpacity(0.4)
                  : AppColors.borderSubtle,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildThumbnail(file),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  file.name,
                  style: AppTextStyles.micro.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                file.sizeStr,
                style: AppTextStyles.nano.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildThumbnail(ScannedFile file) {
    if (file.thumbnailPath != null) {
      return Image.file(
        File(file.thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(file),
      );
    }
    return _buildFallbackIcon(file);
  }

  Widget _buildFallbackIcon(ScannedFile file) {
    IconData icon;
    Color color;
    switch (file.category) {
      case FileCategory.videos:
        icon = LucideIcons.video;
        color = const Color(0xFF3b82f6);
        break;
      case FileCategory.audio:
        icon = LucideIcons.music;
        color = const Color(0xFF10b981);
        break;
      case FileCategory.images:
        icon = LucideIcons.image;
        color = const Color(0xFFf59e0b);
        break;
      case FileCategory.docs:
        icon = LucideIcons.fileText;
        color = const Color(0xFFef4444);
        break;
      default:
        icon = LucideIcons.folder;
        color = AppColors.violet;
    }
    return Container(
      color: color.withOpacity(0.1),
      child: Center(child: Icon(icon, color: color, size: 24)),
    );
  }

  void _showImagePreview(BuildContext context, ScannedFile file) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Background blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(color: Colors.black.withOpacity(0.9)),
              ),
            ),
            // Image with zoom
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: file.path,
                  child: Image.file(File(file.path), fit: BoxFit.contain),
                ),
              ),
            ),
            // UI elements
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      file.name,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.share2, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
