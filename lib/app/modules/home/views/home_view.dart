import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/home_controller.dart';
import '../../../data/models/video_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pod_player/pod_player.dart';
import '../../../data/services/media_playback_service.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategories(),
            Expanded(
              child: Obx(
                () => Stack(
                  children: [
                    ListView(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        const SizedBox(height: 8),
                        _buildCarouselSlider(),
                        const SizedBox(height: 20),
                        _buildSocialLinks(),
                        const SizedBox(height: 24),
                        _buildSectionHeader("Recommended for You"),
                        const SizedBox(height: 12),
                        if (controller.isLoadingVideos.value) ...[
                          _buildLoadingSkeletons(),
                        ] else if (controller.filteredVideos.isNotEmpty) ...[
                          if (controller.activeCategory.value == 'images')
                            _buildImageGrid()
                          else ...[
                            _buildFeaturedCard(controller.filteredVideos[0]),
                            const SizedBox(height: 20),
                            _buildSectionHeader("Videos"),
                            const SizedBox(height: 12),
                            ...controller.filteredVideos
                                .skip(1)
                                .map((video) => _buildVideoListTile(video)),
                          ],
                          if (controller.isMoreLoading.value)
                            _buildLoadMoreIndicator(),
                        ] else ...[
                          _buildEmptyResults(),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                    if (controller.isExtracting.value) _buildLoadingOverlay(),
                  ],
                ),
              ),
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradientDiag,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.download,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text("VidGet", style: AppTextStyles.h2),
            ],
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bell,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.violet,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => controller.urlInput.value = v,
                    decoration: InputDecoration(
                      hintText: "Paste URL or search...",
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    style: AppTextStyles.body,
                  ),
                ),
                const Icon(
                  LucideIcons.mic,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Obx(
                  () => controller.urlInput.value.isNotEmpty
                      ? AppGradientButton(
                          height: 32,
                          borderRadius: 10,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onTap: () => controller.handleAction(),
                          child: Text(
                            "Go",
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().scale(duration: 150.ms)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: controller.quickPaste
                  .map(
                    (site) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => controller.urlInput.value = site,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            site,
                            style: AppTextStyles.micro.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final cat = controller.categories[index];
          return Obx(() {
            final isActive = controller.activeCategory.value == cat['id'];
            return GestureDetector(
              onTap: () => controller.setCategory(cat['id']!),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.violet : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.violet : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    if (isActive)
                      const Icon(
                        LucideIcons.trendingUp,
                        size: 12,
                        color: Colors.white,
                      ).animate().fade().scale(),
                    if (isActive) const SizedBox(width: 6),
                    Text(
                      cat['label']!,
                      style: AppTextStyles.caption.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  "See all",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.violetLight,
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 12,
                  color: AppColors.violetLight,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselSlider() {
    return Obx(() {
      if (controller.carouselVideos.isEmpty) {
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Loading trending videos...",
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }

      return CarouselSlider(
        options: CarouselOptions(
          height: 200,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
        ),
        items: controller.carouselVideos.map((video) {
          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () => controller.toggleInlinePlay(video),
                child: Obx(() {
                  final isActive =
                      controller.activePlayingId.value == video.id.toString();
                  final isReady =
                      isActive &&
                      controller.podController != null &&
                      !controller.isPlayerLoading.value;

                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 0.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black,
                      image: (!isReady)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(video.thumb),
                              fit: BoxFit.cover,
                              onError: (e, s) =>
                                  print("Carousel Image Error: $e"),
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (isReady)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: PodVideoPlayer(
                              controller: controller.podController!,
                            ),
                          )
                        else ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child:
                                  Icon(
                                        isActive &&
                                                controller.isPlayerLoading.value
                                            ? LucideIcons.loader2
                                            : LucideIcons.play,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                      .animate(
                                        target:
                                            (isActive &&
                                                controller
                                                    .isPlayerLoading
                                                    .value)
                                            ? 1
                                            : 0,
                                      )
                                      .rotate(duration: GetNumUtils(2).seconds),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.violet,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "TRENDING",
                                    style: AppTextStyles.micro.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${video.channel} • ${video.views}",
                                  style: AppTextStyles.micro.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              );
            },
          );
        }).toList(),
      );
    });
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Popular Platforms"),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: controller.socialPlatforms
                .map(
                  (platform) => Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: GestureDetector(
                      onTap: () =>
                          controller.urlInput.value = platform['query']!,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CachedNetworkImage(
                              imageUrl: platform['icon']!,
                              fit: BoxFit.contain,
                              fadeInDuration: const Duration(milliseconds: 300),
                              placeholder: (context, url) => Container(
                                padding: const EdgeInsets.all(8),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  platform['name']![0],
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.violet,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            platform['name']!,
                            style: AppTextStyles.micro.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(VideoItem video) {
    return Obx(() {
      final isActive = controller.activePlayingId.value == video.id.toString();
      final isReady =
          isActive &&
          controller.podController != null &&
          !controller.isPlayerLoading.value;

      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
          image: !isReady
              ? DecorationImage(
                  image: CachedNetworkImageProvider(video.thumb),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (isReady)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PodVideoPlayer(controller: controller.podController!),
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => controller.toggleInlinePlay(video),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child:
                        Icon(
                              isActive && controller.isPlayerLoading.value
                                  ? LucideIcons.loader2
                                  : LucideIcons.play,
                              size: 20,
                              color: Colors.white,
                            )
                            .animate(
                              target:
                                  (isActive && controller.isPlayerLoading.value)
                                  ? 1
                                  : 0,
                            )
                            .rotate(duration: GetNumUtils(2).seconds),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "LIVE",
                            style: AppTextStyles.nano.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violet,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "4K",
                            style: AppTextStyles.nano.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${video.channel} • ${video.views} views",
                          style: AppTextStyles.micro.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Obx(() => _buildDownloadButton(video)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildVideoListTile(VideoItem video) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => controller.toggleInlinePlay(video),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Obx(() {
                    final isActive =
                        controller.activePlayingId.value == video.id.toString();
                    final isReady =
                        isActive &&
                        controller.podController != null &&
                        !controller.isPlayerLoading.value;

                    if (isReady && controller.podController != null) {
                      return SizedBox(
                        width: 100,
                        height: 64,
                        child: PodVideoPlayer(
                          controller: controller.podController!,
                        ),
                      );
                    }

                    return CachedNetworkImage(
                      imageUrl: video.thumb,
                      width: 100,
                      height: 64,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) => Container(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(
                          LucideIcons.image,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    );
                  }),
                ),
                Obx(() {
                  final isActive =
                      controller.activePlayingId.value == video.id.toString();
                  if (isActive &&
                      !controller.isPlayerLoading.value &&
                      controller.podController != null) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(video.duration, style: AppTextStyles.nano),
                    ),
                  );
                }),
                _buildThumbnailDurationOverlay(video),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.channel,
                  style: AppTextStyles.micro.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 8,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          video.views,
                          style: AppTextStyles.micro.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.quality,
                        style: AppTextStyles.nano.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => _buildInlinePlayButton(video)),
              const SizedBox(width: 8),
              Obx(() => _buildDownloadButton(video, isCircle: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailDurationOverlay(VideoItem video) {
    return Obx(() {
      final isActive = controller.activePlayingId.value == video.id.toString();
      if (isActive &&
          !controller.isPlayerLoading.value &&
          controller.podController != null) {
        return const SizedBox.shrink();
      }
      return Positioned(
        bottom: 4,
        right: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(video.duration, style: AppTextStyles.nano),
        ),
      );
    });
  }

  Widget _buildInlinePlayButton(VideoItem video) {
    final isActive = controller.activePlayingId.value == video.id.toString();
    final isLoading = isActive && controller.isPlayerLoading.value;
    final isPlaying =
        isActive &&
        controller.podController != null &&
        controller.podController!.isVideoPlaying;

    return GestureDetector(
      onTap: () => controller.toggleInlinePlay(video),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.violet.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.violet,
                ),
              )
            : Icon(
                isPlaying ? LucideIcons.pause : LucideIcons.play,
                size: 14,
                color: isActive ? AppColors.violet : AppColors.textPrimary,
              ),
      ),
    );
  }

  Widget _buildRecentlyDownloaded() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          final thumbs = [
            "https://images.unsplash.com/photo-1758186355698-bd0183fc75ed?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0ZWNobm9sb2d5JTIwZ2FkZ2V0JTIwcmV2aWV3fGVufDF8fHx8MTc3NjU5NTQ4OHww&ixlib=rb-4.1.0&q=80&w=400",
            "https://images.unsplash.com/photo-1635661988046-306631057df3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb29raW5nJTIwZm9vZCUyMHJlY2lwZXxlbnwxfHx8fDE3NzY1OTU0ODl8MA&ixlib=rb-4.1.0&q=80&w=400",
            "https://images.unsplash.com/photo-1689793354800-de168c0a4c9b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtdXNpYyUyMGNvbmNlcnQlMjBzdGFnZSUyMGxpZ2h0c3xlbnwxfHx8fDE3NzY1OTU0ODd8MA&ixlib=rb-4.1.0&q=80&w=400",
          ];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: CachedNetworkImageProvider(thumbs[index]),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 6,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Done",
                        style: AppTextStyles.nano.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.violet),
            const SizedBox(height: 20),
            Text(
              "Extracting Video...",
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This might take a few seconds",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade();
  }

  Widget _buildEmptyResults() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(
          LucideIcons.searchX,
          size: 48,
          color: AppColors.textTertiary.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          "No results found",
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          "Try searching with different keywords",
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildLoadingSkeletons() {
    return Column(
      children:
          List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.1)),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.violet,
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: controller.filteredVideos.length,
      itemBuilder: (context, index) {
        final item = controller.filteredVideos[index];
        return GestureDetector(
          onTap: () => controller.playVideo(item),
          child:
              ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.thumb,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.micro.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fade(duration: 300.ms, delay: (index * 50).ms)
                  .slideY(begin: 0.1),
        );
      },
    );
  }

  Widget _buildDownloadButton(VideoItem video, {bool isCircle = false}) {
    final isDownloading = controller.isDownloading(video.id);
    final progress = controller.getDownloadProgress(video.id);

    if (isCircle) {
      return GestureDetector(
        onTap: () => controller.handleDownload(video),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDownloading
                ? AppColors.violet.withOpacity(0.1)
                : AppColors.bgCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.violet.withOpacity(0.2)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isDownloading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress <= 0 ? null : progress / 100,
                    strokeWidth: 2,
                    color: AppColors.violetLight,
                    backgroundColor: Colors.white10,
                  ),
                ),
              Icon(
                    isDownloading ? LucideIcons.loader2 : LucideIcons.download,
                    size: 14,
                    color: isDownloading
                        ? AppColors.violetLight
                        : Colors.white70,
                  )
                  .animate(target: isDownloading ? 1 : 0)
                  .rotate(duration: GetNumUtils(2).seconds),
            ],
          ),
        ),
      );
    }

    return AppGradientButton(
      height: 28,
      borderRadius: 15,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: () => controller.handleDownload(video),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDownloading) ...[
            SizedBox(
              width: 12,
              height: 12,
              child:
                  CircularProgressIndicator(
                        value: progress <= 0 ? null : progress / 100,
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: GetNumUtils(1).seconds),
            ),
            const SizedBox(width: 8),
            Text(
              progress > 0 ? "${progress.toInt()}%" : "Wait",
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            const Icon(LucideIcons.download, size: 10, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              "Download",
              style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
