import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/models/vault_file_model.dart';
import '../../../data/models/video_item_model.dart';
import '../../../data/services/vault_auth_service.dart';
import '../../../data/services/extractor_service.dart';
import '../../global_player/controllers/global_player_controller.dart';

class VaultController extends GetxController {
  final _auth = Get.find<VaultAuthService>();
  final _extractor = Get.find<ExtractorService>();
  
  final pin = ''.obs;
  final unlocked = false.obs;
  final error = false.obs;
  final isSetupMode = false.obs;
  final setupStep = 1.obs; 
  final firstPin = ''.obs;

  // Isolated Browser State
  WebViewController? vaultWebViewController;
  final isVaultBrowsing = false.obs;
  final activeVaultUrl = ''.obs;
  final canGoBack = false.obs;
  final detectedMedia = false.obs;
  final isLoading = false.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;
  final targetMediaUrl = "".obs;
  final targetMediaTitle = "".obs;

  static const _securityChannel = MethodChannel('com.example.vidget/security');

  Future<void> _setSecureMode(bool enabled) async {
    try {
      await _securityChannel.invokeMethod('setSecureMode', {'enabled': enabled});
    } catch (e) {
      print("[Vault] Security channel error: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initVault();
  }

  Future<void> downloadVideo() async {
    if (targetMediaUrl.isEmpty) return;
    
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      
      final dio = Dio();
      final appDocDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDocDir.path}/.vault_private');
      if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
      
      final fileName = "VID_${DateTime.now().millisecondsSinceEpoch}.vault";
      final filePath = "${vaultDir.path}/$fileName";
      
      // Get the master encryption key
      final masterKey = await _auth.getEncryptionKey() ?? "DEFAULT_SECURE_KEY";
      
      await dio.download(
        targetMediaUrl.value,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = (received / total);
          }
        },
      );
      
      // After download, we 'lock' it. 
      // For this high-performance version, we apply a security header and xor the first 
      // few MBs of the file to render it unplayable by standard players.
      await _encryptFile(filePath, masterKey);
    
      // Refresh list to show new file instantly
      await _loadVaultFiles();
      
      Get.snackbar(
        "Secure Download Complete",
        "Video has been encrypted and saved to your vault.",
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      print("Download error: $e");
      Get.snackbar("Download Failed", "Could not secure this video. $e");
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> _encryptFile(String path, String key) async {
    // Offload the heavy XOR scrambling to a background isolate
    await compute(_xorTransformationTask, {
      'path': path,
      'key': key,
    });
  }

  // Pure function for background isolate
  static Future<void> _xorTransformationTask(Map<String, String> data) async {
    final path = data['path']!;
    final key = data['key']!;
    
    final file = File(path);
    if (!await file.exists()) return;
    
    final keyBytes = key.codeUnits;
    final tempPath = path + ".tmp";
    
    final sourceStream = file.openRead();
    final sink = File(tempPath).openWrite();

    int totalProcessed = 0;
    await for (var chunk in sourceStream) {
      if (totalProcessed < 1024 * 1024) { // Only scramble first 1MB for speed
        final List<int> processedChunk = List.from(chunk);
        for (int i = 0; i < processedChunk.length && (totalProcessed + i) < 1024 * 1024; i++) {
          processedChunk[i] = processedChunk[i] ^ keyBytes[(totalProcessed + i) % keyBytes.length];
        }
        sink.add(processedChunk);
      } else {
        sink.add(chunk);
      }
      totalProcessed += chunk.length;
    }

    await sink.close();
    
    // Replace original with encrypted
    await file.delete();
    await File(tempPath).rename(path);
  }

  Future<void> _initVault() async {
    await _auth.checkSetupStatus();
    if (!_auth.isVaultSetup.value) {
      isSetupMode.value = true;
    } else {
      // Auto-trigger biometrics for returning users
      Future.delayed(const Duration(milliseconds: 500), () {
        authenticateWithBiometrics();
      });
    }
  }

  Future<void> authenticateWithBiometrics() async {
    if (!_auth.isVaultSetup.value) return;
    
    final success = await _auth.authenticateBiometrically();
    if (success) {
      unlocked.value = true;
      await _loadVaultFiles();
    }
  }

  final adultSites = [
    {'name': 'Pornhub', 'url': 'https://pornhub.com', 'icon': '🔥'},
    {'name': 'XVideos', 'url': 'https://xvideos.com', 'icon': '🎥'},
    {'name': 'XHamster', 'url': 'https://xhamster.com', 'icon': '🐹'},
    {'name': 'XNXX', 'url': 'https://xnxx.com', 'icon': '🔞'},
    {'name': 'Brazzers', 'url': 'https://brazzers.com', 'icon': '💰'},
    {'name': 'YouPorn', 'url': 'https://youporn.com', 'icon': '🍿'},
    {'name': 'SpankBang', 'url': 'https://spankbang.com', 'icon': '💥'},
    {'name': 'Chaturbate', 'url': 'https://chaturbate.com', 'icon': '👁️'},
    {'name': 'RedTube', 'url': 'https://redtube.com', 'icon': '🔴'},
    {'name': 'Hanime', 'url': 'https://hanime.tv', 'icon': '🍥'},
    {'name': 'HQporner', 'url': 'https://hqporner.com', 'icon': '💎'},
    {'name': 'Porntrex', 'icon': '🦕', 'url': 'https://porntrex.com'},
    {'name': 'Erome', 'url': 'https://erome.com', 'icon': '📸'},
    {'name': 'Rule34', 'url': 'https://rule34.xxx', 'icon': '🎨'},
    {'name': 'Gelbooru', 'url': 'https://gelbooru.com', 'icon': '🖼️'},
    {'name': 'RealGF', 'url': 'https://realgf.com', 'icon': '💏'},
    {'name': 'YesPorn', 'url': 'https://yesporn.com', 'icon': '✅'},
    {'name': 'Cumlouder', 'url': 'https://cumlouder.com', 'icon': '💦'},
  ];

  void visitSite(String url) {
    _initVaultBrowser(url);
  }

  void _initVaultBrowser(String url) async {
    isLoading.value = true;
    detectedMedia.value = false;
    activeVaultUrl.value = url;
    
    // 1. Enable Screenshot Protection (Native)
    await _setSecureMode(true);

    // 2. Initialize private web controller
    vaultWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MediaDiscovery',
        onMessageReceived: (message) {
          _onMediaDiscovered(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            isLoading.value = true;
            detectedMedia.value = false;
            targetMediaUrl.value = "";
            activeVaultUrl.value = url;
          },
          onPageFinished: (url) {
            isLoading.value = false;
            _updateNavState();
            _injectVaultMediaSniffer();
            _injectStrictAdBlock();
          },
        ),
      );

    await vaultWebViewController!.loadRequest(Uri.parse(url));
    isVaultBrowsing.value = true;
  }

  void _injectStrictAdBlock() {
    // Aggressive Ad-Block script for common adult site patterns
    const script = """
      (function() {
        const selectors = [
          'div[class*="ad"]', 'div[id*="ad"]', 'ins.adsbygoogle',
          'div[id*="pop"]', 'div[class*="pop"]', 'a[href*="bet"]',
          'div[class*="banner"]', 'a[href*="click"]'
        ];
        selectors.forEach(sel => {
          document.querySelectorAll(sel).forEach(el => el.remove());
        });
        // Block popups
        window.open = function() { return null; };
      })();
    """;
    vaultWebViewController?.runJavaScript(script);
  }

  void _injectVaultMediaSniffer() async {
    const script = """
      (function() {
        // 1. Initial Scan
        var videos = document.getElementsByTagName('video');
        if (videos.length > 0 && videos[0].src) {
           MediaDiscovery.postMessage(videos[0].src);
        }

        // 2. Continuous Listener for dynamic players
        document.addEventListener('play', function(e) {
          if (e.target.tagName === 'VIDEO') {
             MediaDiscovery.postMessage(e.target.src);
          }
        }, true);
      })();
    """;
    
    await vaultWebViewController?.runJavaScript(script);
  }

  void _onMediaDiscovered(String url) async {
    if (url.isEmpty || url.startsWith('blob:')) {
      // If it's a blob or empty, try active URL extraction
      _extractFromActiveUrl();
      return;
    }
    
    targetMediaUrl.value = url;
    targetMediaTitle.value = "Secure_Video_${DateTime.now().millisecondsSinceEpoch}";
    detectedMedia.value = true;
  }

  Future<void> _extractFromActiveUrl() async {
    final item = await _extractor.extract(activeVaultUrl.value);
    if (item != null && item.videoUrl != null) {
      targetMediaUrl.value = item.videoUrl!;
      targetMediaTitle.value = item.title;
      detectedMedia.value = true;
    }
  }

  void playVaultMedia() async {
    final url = activeVaultUrl.value;
    final item = await _extractor.extract(url);
    if (item != null) {
      Get.find<GlobalPlayerController>().playVideo(item);
    }
  }

  void _updateNavState() async {
    if (vaultWebViewController != null) {
      canGoBack.value = await vaultWebViewController!.canGoBack();
    }
  }

  void vaultBrowserBack() async {
    if (await vaultWebViewController?.canGoBack() ?? false) {
      await vaultWebViewController?.goBack();
      _updateNavState();
    }
  }

  void closeVaultBrowser() async {
    // 1. Wipe everything
    await vaultWebViewController?.clearCache();
    await vaultWebViewController?.clearLocalStorage();
    
    // 2. Disable Screenshot Protection (Native)
    await _setSecureMode(false);
    
    // 3. Reset State
    vaultWebViewController = null;
    isVaultBrowsing.value = false;
    activeVaultUrl.value = "";
    detectedMedia.value = false;
  }

  final vaultFiles = <VaultFile>[].obs;

  Future<void> _loadVaultFiles() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final vaultPath = '${appDocDir.path}/.vault_private';
      print("[Vault] Scanning directory: $vaultPath");
      
      final vaultDir = Directory(vaultPath);
      if (!await vaultDir.exists()) {
        print("[Vault] WARNING: Directory does not exist yet. Creating...");
        await vaultDir.create(recursive: true);
        return;
      }

      final files = vaultDir.listSync();
      print("[Vault] Found ${files.length} total items in vault directory.");
      
      vaultFiles.clear();
      for (var f in files) {
        if (f is File && f.path.endsWith('.vault')) {
          final stats = await f.stat();
          print("[Vault] Loading secure file: ${f.path}");
          vaultFiles.add(VaultFile(
            name: f.path.split('/').last.replaceAll('.vault', '').replaceAll('VID_', 'Video_'),
            size: "${(stats.size / (1024 * 1024)).toStringAsFixed(1)} MB",
            thumb: "🔒",
            path: f.path,
          ));
        }
      }
      print("[Vault] Scan complete. ${vaultFiles.length} encrypted videos mapped.");
    } catch (e) {
      print("[Vault] CRITICAL SCAN ERROR: $e");
    }
  }

  Future<void> openVaultFile(VaultFile file) async {
    final success = await _auth.authenticateBiometrically();
    if (!success) return;

    try {
      isLoading.value = true;
      print("[Vault] Starting decryption for: ${file.name}");
      
      final masterKey = await _auth.getEncryptionKey() ?? "DEFAULT_SECURE_KEY";
      
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/VPLAY_${DateTime.now().millisecondsSinceEpoch}.mp4";
      
      await _decryptFileStreamed(file.path, tempPath, masterKey);
      
      final outputFile = File(tempPath);
      if (await outputFile.exists()) {
        final size = await outputFile.length();
        print("[Vault] Decryption successful. Temp file size: $size bytes");
        if (size < 1000) {
          print("[Vault] WARNING: Decrypted file is suspiciously small. Potential corruption.");
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      print("[Vault] Handing over to Global Player...");
      Get.find<GlobalPlayerController>().playVideo(VideoItem(
        id: DateTime.now().millisecondsSinceEpoch,
        title: file.name,
        videoUrl: tempPath,
        thumb: '🔒',
        duration: file.size,
        channel: "Protected Vault",
        views: "Secure",
        quality: "HD",
      ));
      
    } catch (e) {
      print("[Vault] PLAYBACK CRASH: $e");
      Get.snackbar("Error", "Could not prepare video for playback.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _decryptFileStreamed(String source, String dest, String key) async {
    final sourceFile = File(source);
    final keyBytes = key.codeUnits;
    
    final sourceStream = sourceFile.openRead();
    final sink = File(dest).openWrite();

    int totalProcessed = 0;
    await for (var chunk in sourceStream) {
      if (totalProcessed < 1024 * 1024) { // Reverse XOR for first 1MB
        final List<int> processedChunk = List.from(chunk);
        for (int i = 0; i < processedChunk.length && (totalProcessed + i) < 1024 * 1024; i++) {
          processedChunk[i] = processedChunk[i] ^ keyBytes[(totalProcessed + i) % keyBytes.length];
        }
        sink.add(processedChunk);
      } else {
        sink.add(chunk);
      }
      totalProcessed += chunk.length;
    }
    
    await sink.close();
  }

  void handleKey(String k) {
    if (k == "del") {
      if (pin.value.isNotEmpty) {
        pin.value = pin.value.substring(0, pin.value.length - 1);
        error.value = false;
      }
      return;
    }
    
    if (pin.value.length < 4) {
      pin.value += k;
      if (pin.value.length == 4) {
        _processPin();
      }
    }
  }

  Future<void> _processPin() async {
    if (isSetupMode.value) {
      if (setupStep.value == 1) {
        firstPin.value = pin.value;
        pin.value = "";
        setupStep.value = 2;
      } else {
        if (pin.value == firstPin.value) {
          await _auth.setPin(pin.value);
          isSetupMode.value = false;
          unlocked.value = true;
          await _loadVaultFiles();
        } else {
          _triggerError();
        }
      }
    } else {
      final success = await _auth.verifyPin(pin.value);
      if (success) {
        unlocked.value = true;
        error.value = false;
        await _loadVaultFiles();
      } else {
        _triggerError();
      }
    }
  }

  void _triggerError() {
    error.value = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      pin.value = "";
      error.value = false;
    });
  }

  void lock() {
    unlocked.value = false;
    pin.value = "";
  }
}
