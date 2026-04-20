import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/video_item_model.dart';
import '../../../../data/models/video_format_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_gradient_button.dart';

class DownloadOptionsSheet extends StatelessWidget {
  final VideoItem video;
  final List<VideoFormat> formats;
  final Function(VideoFormat) onSelect;

  const DownloadOptionsSheet({
    super.key,
    required this.video,
    required this.formats,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(color: AppColors.border),
          _buildFormatList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: video.thumb,
              width: 100,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  video.channel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatList() {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: formats.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final format = formats[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: format.isAudioOnly 
                      ? Colors.orange.withOpacity(0.1) 
                      : AppColors.violet.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  format.isAudioOnly ? LucideIcons.music : LucideIcons.video,
                  size: 18,
                  color: format.isAudioOnly ? Colors.orange : AppColors.violetLight,
                ),
              ),
              title: Text(
                format.quality,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${format.extension.toUpperCase()} • ${format.sizeLabel}",
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
              trailing: AppGradientButton(
                width: 44,
                height: 32,
                borderRadius: 10,
                padding: EdgeInsets.zero,
                onTap: () {
                  Get.back();
                  onSelect(format);
                },
                child: const Icon(LucideIcons.download, size: 14, color: Colors.white),
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
        },
      ),
    );
  }
}
