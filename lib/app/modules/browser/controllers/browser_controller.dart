import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/extractor_service.dart';
import '../../../routes/app_routes.dart';

class BrowserTab {
  final int id;
  final RxString title = "New Tab".obs;
  final RxString url = "".obs;
  final RxString favicon = "🌐".obs;
  final RxBool isHome = true.obs;
  WebViewController? controller;

  BrowserTab({required this.id, String? initialUrl, this.controller}) {
    if (initialUrl != null && initialUrl.isNotEmpty) {
      url.value = initialUrl;
      isHome.value = false;
    }
  }
}

class BrowserController extends GetxController {
  final _extractor = Get.find<ExtractorService>();
  
  final tabs = <BrowserTab>[].obs;
  final activeTabId = 0.obs;
  final urlInput = "".obs;
  final showTabs = false.obs;
  final showBookmarks = false.obs;
  final showSuggestions = false.obs;
  final isPrivate = false.obs;
  final detectedMedia = false.obs;
  final adBlockOn = true.obs;
  final isLoading = false.obs;

  final bookmarks = [
    {'name': 'YouTube', 'url': 'https://youtube.com', 'favicon': '🎬', 'color': '#FF0000'},
    {'name': 'TikTok', 'url': 'https://tiktok.com', 'favicon': '🎵', 'color': '#EE1D52'},
    {'name': 'Instagram', 'url': 'https://instagram.com', 'favicon': '📸', 'color': '#E1306C'},
    {'name': 'Twitter/X', 'url': 'https://twitter.com', 'favicon': '🐦', 'color': '#1DA1F2'},
    {'name': 'Google', 'url': 'https://google.com', 'favicon': '🔍', 'color': '#4285F4'},
    {'name': 'Reddit', 'url': 'https://reddit.com', 'favicon': '🤖', 'color': '#FF4500'},
  ];

  @override
  void onInit() {
    super.onInit();
    addNewTab();
  }

  BrowserTab? get activeTab => tabs.firstWhereOrNull((t) => t.id == activeTabId.value);

  void addNewTab({String? url}) {
    final newId = DateTime.now().millisecondsSinceEpoch;
    final webController = WebViewController();
    
    webController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webController.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          isLoading.value = true;
          detectedMedia.value = false;
          final tab = tabs.firstWhereOrNull((t) => t.id == newId);
          if (tab != null) {
            tab.isHome.value = false;
            tab.url.value = url;
          }
        },
        onPageFinished: (url) async {
          isLoading.value = false;
          final tab = tabs.firstWhereOrNull((t) => t.id == newId);
          if (tab != null) {
            final title = await webController.getTitle();
            if (title != null && title.isNotEmpty) tab.title.value = title;
          }
          _injectMediaSniffer();
        },
        onUrlChange: (change) {
          if (activeTabId.value == newId) {
            urlInput.value = change.url ?? '';
          }
        },
      ),
    );

    if (url != null && url.isNotEmpty) {
      webController.loadRequest(Uri.parse(url));
    }

    final newTab = BrowserTab(
      id: newId, 
      initialUrl: url,
      controller: webController,
    );
    
    tabs.add(newTab);
    activeTabId.value = newId;
    urlInput.value = url ?? "";
    showTabs.value = false;
  }

  void _injectMediaSniffer() async {
    if (detectedMedia.value) return;
    final controller = activeTab?.controller;
    if (controller == null) return;

    const script = """
      (function() {
        var videos = document.getElementsByTagName('video');
        if (videos.length > 0) {
          return videos[0].src || document.querySelector('meta[property="og:video"]')?.content;
        }
        return null;
      })();
    """;
    
    try {
      final result = await controller.runJavaScriptReturningResult(script);
      // ignore: unnecessary_null_comparison
      if (result != null && result.toString() != "null") {
        detectedMedia.value = true;
      }
    } catch (e) {
      print("Sniffer error: $e");
    }
  }

  void handleMediaAction() async {
    final url = urlInput.value;
    if (url.isEmpty) return;
    
    final item = await _extractor.extract(url);
    if (item != null && item.videoUrl != null) {
      Get.toNamed(Routes.VIDEO_PLAYER, arguments: item);
    }
  }

  void closeTab(int id) {
    if (tabs.length > 1) {
      int index = tabs.indexWhere((t) => t.id == id);
      tabs.removeAt(index);
      if (activeTabId.value == id) {
        activeTabId.value = tabs.first.id;
        urlInput.value = activeTab?.url.value ?? "";
      }
    }
  }

  void navigateTo(String url, String title, String favicon) {
    String searchUrl = url;
    if (!url.startsWith('http')) {
      if (url.contains('.') && !url.contains(' ')) {
        searchUrl = 'https://$url';
      } else {
        searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }
    
    final tab = activeTab;
    if (tab != null) {
      tab.isHome.value = false;
      tab.url.value = searchUrl;
      tab.controller?.loadRequest(Uri.parse(searchUrl));
    }
    
    showSuggestions.value = false;
    urlInput.value = searchUrl;
  }

  void goHome() {
    final tab = activeTab;
    if (tab != null) {
      tab.isHome.value = true;
      tab.url.value = "";
      urlInput.value = "";
    }
  }
}
