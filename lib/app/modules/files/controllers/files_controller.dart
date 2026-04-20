import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/services/file_scanner_service.dart';
import '../../../data/services/media_playback_service.dart';

class FilesController extends GetxController {
  final _scanner = Get.find<FileScannerService>();
  final _playback = Get.find<MediaPlaybackService>();

  final activeCategory = 'All'.obs;
  final viewMode = 'list'.obs; // 'list' or 'grid'
  final searchQuery = ''.obs;
  final selectedPaths = <String>[].obs;
  final sortBy = 'date'.obs;
  final showSortMenu = false.obs;
  final featuredFiles = <ScannedFile>[].obs;


  @override
  void onInit() {
    super.onInit();
    refreshFiles();
  }

  Future<void> refreshFiles() async {
    await _scanner.scanStorage();
    _updateFeatured();
  }

  void _updateFeatured() {
    // Get the 5 most recent videos or images for the banner
    final media = _scanner.allFiles
        .where((f) => f.category == FileCategory.videos || f.category == FileCategory.images)
        .toList();
    
    media.sort((a, b) => b.modified.compareTo(a.modified));
    featuredFiles.assignAll(media.take(5).toList());
  }


  List<Map<String, dynamic>> get categories {
    final files = _scanner.allFiles;
    int videoCount = files.where((f) => f.category == FileCategory.videos).length;
    int audioCount = files.where((f) => f.category == FileCategory.audio).length;
    int imageCount = files.where((f) => f.category == FileCategory.images).length;
    int docCount = files.where((f) => f.category == FileCategory.docs).length;

    int totalSize = files.fold(0, (sum, f) => sum + f.size);
    String formatSize(int s) {
      if (s < 1024 * 1024) return "${(s / 1024).toStringAsFixed(1)} KB";
      if (s < 1024 * 1024 * 1024) return "${(s / (1024 * 1024)).toStringAsFixed(1)} MB";
      return "${(s / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
    }

    return [
      {'id': 'All', 'label': 'All', 'icon': LucideIcons.folder, 'color': const Color(0xFF8b5cf6), 'count': files.length, 'size': formatSize(totalSize)},
      {'id': 'Videos', 'label': 'Videos', 'icon': LucideIcons.video, 'color': const Color(0xFF3b82f6), 'count': videoCount, 'size': '...'},
      {'id': 'Audio', 'label': 'Audio', 'icon': LucideIcons.music, 'color': const Color(0xFF10b981), 'count': audioCount, 'size': '...'},
      {'id': 'Images', 'label': 'Images', 'icon': LucideIcons.image, 'color': const Color(0xFFf59e0b), 'count': imageCount, 'size': '...'},
      {'id': 'Documents', 'label': 'Docs', 'icon': LucideIcons.fileText, 'color': const Color(0xFFef4444), 'count': docCount, 'size': '...'},
    ];
  }

  List<ScannedFile> get filteredFiles {
    return _scanner.allFiles.where((f) {
      final catMatch = activeCategory.value == 'All' || f.category.name.toLowerCase() == activeCategory.value.toLowerCase();
      final searchMatch = f.name.toLowerCase().contains(searchQuery.value.toLowerCase());
      return catMatch && searchMatch;
    }).toList();
  }

  void playFile(ScannedFile file) {
    if (file.category == FileCategory.audio || file.category == FileCategory.videos) {
      _playback.playFile(file.path, file.name);
    } else if (file.category == FileCategory.images) {
      // Handled by the view's preview dialog for now
      // but we could pass state here if needed
    }
  }

  void toggleSelect(String path) {
    if (selectedPaths.contains(path)) {
      selectedPaths.remove(path);
    } else {
      selectedPaths.add(path);
    }
  }

  bool isSelected(String path) => selectedPaths.contains(path);
  bool get isSelecting => selectedPaths.isNotEmpty;
  void clearSelection() => selectedPaths.clear();
  bool get isScanning => _scanner.isScanning.value;
}
