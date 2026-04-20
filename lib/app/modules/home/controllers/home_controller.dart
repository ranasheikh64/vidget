import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:vidget/app/data/services/media_playback_service.dart';
import '../../../data/models/video_item_model.dart';
import '../../../data/services/extractor_service.dart';
import '../../../data/services/download_service.dart';
import '../../global_player/controllers/global_player_controller.dart';
import '../views/widgets/download_options_sheet.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
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
  final carouselVideos = <VideoItem>[].obs;
  
  // Inline Playback State
  final activePlayingId = "".obs;
  PodPlayerController? podController;
  final isPlayerLoading = false.obs;
  
  final quickPaste = ["youtube.com", "instagram.com", "tiktok.com", "twitter.com"];
  
  final socialPlatforms = [
    {'id': 'youtube', 'name': 'YouTube', 'icon': 'https://raw.githubusercontent.com/Anil-M/social-icons/master/youtube.png', 'query': 'youtube.com'},
    {'id': 'instagram', 'name': 'Instagram', 'icon': 'https://raw.githubusercontent.com/Anil-M/social-icons/master/instagram.png', 'query': 'instagram.com'},
    {'id': 'tiktok', 'name': 'TikTok', 'icon': 'https://raw.githubusercontent.com/Anil-M/social-icons/master/tiktok.png', 'query': 'tiktok.com'},
    {'id': 'facebook', 'name': 'Facebook', 'icon': 'https://raw.githubusercontent.com/Anil-M/social-icons/master/facebook.png', 'query': 'facebook.com'},
    {'id': 'twitter', 'name': 'Twitter', 'icon': 'https://raw.githubusercontent.com/Anil-M/social-icons/master/twitter.png', 'query': 'twitter.com'},
  ];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    scrollController = ScrollController()..addListener(_scrollListener);
    fetchVideos('trending');
    _fetchCarouselVideos();
    
    debounce(urlInput, (String val) {
      if (val.isNotEmpty && !val.startsWith('http')) {
        fetchVideos(val);
      } else if (val.isEmpty) {
        fetchVideos(activeCategory.value);
      }
    }, time: const Duration(milliseconds: 600));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      print("[HomeController] App Backgrounded - Maintaining background audio if active");
    }
  }


  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposePodController();
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
      
      // If we're fetching trending for the main list, use them for carousel too
      if (query == 'trending' && results.isNotEmpty) {
        final trendingSlice = results.take(8).toList();
        trendingSlice.shuffle();
        carouselVideos.assignAll(trendingSlice);
      }
    } catch (e) {
      print("[HomeController] Fetch error: $e");
    } finally {
      isLoadingVideos.value = false;
      _startPreExtractionQueue();
    }
  }

  // Pre-extract first 7 videos for instant playback
  Future<void> _startPreExtractionQueue() async {
    final videosToPreload = filteredVideos.take(7).toList();
    print("[HomeController] Pre-extracting top ${videosToPreload.length} videos...");
    
    for (var video in videosToPreload) {
      String url = video.videoUrl ?? "https://www.youtube.com/watch?v=${video.idString}";
      if (!_extractor.hasCachedFormats(url)) {
        _extractor.getAvailableFormats(url).then((formats) {
          if (formats.isNotEmpty) print("[HomeController] Optimized: ${video.title}");
        }).catchError((e) => null);
        
        // Stagger requests to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }


  Future<void> _fetchCarouselVideos() async {
    // Only fetch extra carousel data if not already populated by trending
    if (carouselVideos.isNotEmpty) return;

    try {
      // Small staggered delay to allow UI to render first list smoothly
      await Future.delayed(const Duration(milliseconds: 1200));
      
      final popular = await _extractor.getCategoryVideos('movies');
      carouselVideos.assignAll(popular.take(10).toList()..shuffle());
    } catch (e) {
      print("[HomeController] Carousel fetch error: $e");
    }
  }

  Future<void> toggleInlinePlay(VideoItem item) async {
    // 1. If clicking the same video while it's playing, pause it
    if (activePlayingId.value == item.id.toString() && podController != null) {
      if (podController!.isVideoPlaying) {
        podController!.pause();
      } else {
        podController!.play();
      }
      return;
    }

    // 2. Dispose of existing controller
    await _disposePodController();

    // 3. Initialize new controller for the selected card
    activePlayingId.value = item.id.toString();
    isPlayerLoading.value = true;

    try {
      String? url = item.videoUrl;
      if (url == null || url.isEmpty) {
        url = "https://www.youtube.com/watch?v=${item.idString}";
      }

      PlayVideoFrom playFrom;
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        playFrom = PlayVideoFrom.youtube(url);
      } else if (url.startsWith('http')) {
        playFrom = PlayVideoFrom.network(url);
      } else {
        playFrom = PlayVideoFrom.file(File(url));
      }

      podController = PodPlayerController(
        playVideoFrom: playFrom,
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
          videoQualityPriority: [720, 480],
        ),
      );

      // Register with GetX globally (no tag needed as only one plays at a time)
      Get.put(podController, permanent: false);
      
      // Sync with background audio service
      Get.find<MediaPlaybackService>().syncWithVideo(podController!, item);
      
      await podController!.initialise();
      
      // Safety check: ensure we didn't cancel during initialization
      if (activePlayingId.value == item.id.toString()) {
        isPlayerLoading.value = false;
        print("[HomeController] Player Ready: ${item.title}");
      } else {
        podController?.dispose();
      }
    } catch (e) {
      print("[HomeController] TogglePlay error: $e");
      activePlayingId.value = "";
      isPlayerLoading.value = false;
    }
  }

  Future<void> _disposePodController() async {
    // 1. Clear ID first to tell Obx to hide the widget IMMEDIATELY
    final oldId = activePlayingId.value;
    activePlayingId.value = "";
    isPlayerLoading.value = false;

    if (podController != null) {
      print("[HomeController] Safely disposing player for: $oldId");
      try {
        // Remove from GetX registry
        Get.delete<PodPlayerController>(force: true);
        
        podController?.pause();
        podController?.dispose();
      } catch (e) {
        print("[HomeController] Disposal warning: $e");
      }
      podController = null;
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
        // Add frame breaks to prevent blocking UI during large list mapping
        for (var result in moreResults) {
          filteredVideos.add(result);
          if (moreResults.indexOf(result) % 5 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
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

  void handleDownload(VideoItem video) async {
    // 1. If it's a direct URL (e.g. from Search Results or Scraped)
    String url = video.videoUrl ?? "";
    if (url.isEmpty) {
       // Try to find URL if it's just a placeholder from YT search
       if (video.channel == "YouTube" || video.channel.contains("Official")) {
         url = "https://www.youtube.com/watch?v=${video.id}";
       } else {
         Get.snackbar("Error", "No download source found for this video.");
         return;
       }
    }

    isExtracting.value = true;
    try {
      final formats = await _extractor.getAvailableFormats(url);
      isExtracting.value = false;

      if (formats.isEmpty) {
        Get.snackbar("Extraction Failed", "No downloadable formats found.");
        return;
      }

      Get.bottomSheet(
        DownloadOptionsSheet(
          video: video,
          formats: formats,
          onSelect: (format) {
            _downloadService.startDownload(video, format);
          },
        ),
      );
    } catch (e) {
      isExtracting.value = false;
      Get.snackbar("Error", "Failed to extract video formats: $e");
    }
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
