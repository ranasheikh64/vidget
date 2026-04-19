import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/video_item_model.dart';
import '../../../data/services/extractor_service.dart';
import '../../../data/services/download_service.dart';
import '../../global_player/controllers/global_player_controller.dart';

class HomeController extends GetxController {
  final _extractor = Get.find<ExtractorService>();
  final _downloadService = Get.find<DownloadService>();
  
  final urlInput = ''.obs;
  final activeCategory = 'trending'.obs;
  final downloadingId = (-1).obs;
  final isExtracting = false.obs;
  final isLoadingVideos = false.obs;
  final isMoreLoading = false.obs;

  late ScrollController scrollController;

  final categories = [
    {'id': 'trending', 'label': 'Trending'},
    {'id': 'movies', 'label': 'Movies'},
    {'id': 'music', 'label': 'Music'},
    {'id': 'images', 'label': 'Images'},
    {'id': 'live', 'label': 'Live TV'},
    {'id': 'sports', 'label': 'Sports'},
    {'id': 'news', 'label': 'News'},
  ];

  final filteredVideos = <VideoItem>[].obs;
  final quickPaste = ["youtube.com", "instagram.com", "tiktok.com", "twitter.com"];

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController()..addListener(_scrollListener);
    fetchVideos('trending');
    
    debounce(urlInput, (String val) {
      if (val.isNotEmpty && !val.startsWith('http')) {
        fetchVideos(val);
      } else if (val.isEmpty) {
        fetchVideos(activeCategory.value);
      }
    }, time: const Duration(milliseconds: 600));
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isMoreLoading.value && !isLoadingVideos.value && filteredVideos.isNotEmpty) {
        loadMore();
      }
    }
  }

  Future<void> fetchVideos(String query) async {
    print("[HomeController] Fetching initial videos for: $query");
    isLoadingVideos.value = true;
    try {
      final results = await _extractor.getCategoryVideos(query);
      filteredVideos.assignAll(results);
    } catch (e) {
      print("[HomeController] Fetch error: $e");
    } finally {
      isLoadingVideos.value = false;
    }
  }

  Future<void> loadMore() async {
    print("[HomeController] Triggering load more...");
    isMoreLoading.value = true;
    try {
      List<VideoItem> moreResults = [];
      if (activeCategory.value == 'images') {
        moreResults = await _extractor.fetchMoreImages();
      } else {
        moreResults = await _extractor.fetchMoreVideos();
      }
      
      if (moreResults.isNotEmpty) {
        filteredVideos.addAll(moreResults);
      }
    } catch (e) {
      print("[HomeController] Load more error: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  void setCategory(String id) {
    activeCategory.value = id;
    fetchVideos(id);
    // Reset scroll to top when category changes
    if (scrollController.hasClients) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void handleAction() async {
    final url = urlInput.value.trim();
    if (url.isEmpty) return;

    if (url.startsWith('http')) {
      await extractAndPlay(url);
    } else {
      fetchVideos(url);
    }
  }

  Future<void> extractAndPlay(String url) async {
    isExtracting.value = true;
    try {
      final item = await _extractor.extract(url);
      if (item != null && item.videoUrl != null) {
        Get.find<GlobalPlayerController>().playVideo(item);
      } else {
        Get.snackbar(
          "Extraction Failed", 
          "Could not find a playable video at this URL.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } finally {
      isExtracting.value = false;
    }
  }

  void handleDownload(VideoItem video) {
    _downloadService.startDownload(video);
  }

  bool isDownloading(int id) {
    return _downloadService.activeDownloads.containsKey(id);
  }

  double getDownloadProgress(int id) {
    return _downloadService.activeDownloads[id]?.progress ?? 0;
  }

  void playVideo(VideoItem item) {
    Get.find<GlobalPlayerController>().playVideo(item);
  }
}
