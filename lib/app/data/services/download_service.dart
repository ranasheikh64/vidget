import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:vidget/app/data/models/download_item_model.dart';
import 'package:vidget/app/data/models/video_item_model.dart';

class DownloadService extends GetxService {
  final Dio _dio = Dio();
  final int _maxConcurrent = 5;
  
  final activeDownloads = <int, DownloadItem>{}.obs;
  final queue = <DownloadItem>[].obs;
  final completedDownloads = <DownloadItem>[].obs;
  final failedDownloads = <DownloadItem>[].obs;

  Future<DownloadService> init() async {
    return this;
  }

  Future<void> startDownload(VideoItem video) async {
    // 1. Check Permissions
    if (!await _checkPermission()) {
      Get.snackbar("Permission Denied", "Storage access is required to download videos.");
      return;
    }

    final id = video.id;
    if (activeDownloads.containsKey(id)) {
      Get.snackbar("Already Downloading", "This video is already in your active list.");
      return;
    }

    // 2. Prepare Download Item
    final newItem = DownloadItem(
      id: id,
      title: video.title,
      site: video.channel,
      format: video.format ?? "MP4",
      quality: video.quality,
      size: "Calculating...",
      progress: 0,
      speed: "0 KB/s",
      eta: "--",
      status: DownloadStatus.queued,
      icon: video.thumb.isNotEmpty ? "🎬" : "📥",
      url: video.videoUrl,
    );

    // 3. Add to Queue or Start
    if (activeDownloads.length < _maxConcurrent) {
      _executeDownload(newItem);
    } else {
      queue.add(newItem);
      Get.snackbar("Queued", "Reached 5 download limit. Item added to queue.");
    }
  }

  Future<void> _executeDownload(DownloadItem item) async {
    activeDownloads[item.id] = item.copyWith(status: DownloadStatus.downloading);
    
    try {
      final savePath = await _getPublicSavePath(item.title, item.format);
      
      DateTime startTime = DateTime.now();

      await _dio.download(
        item.url!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total) * 100;
            
            // Calculate Speed & ETA every second approximate
            final now = DateTime.now();
            final duration = now.difference(startTime).inSeconds;
            
            String speedStr = "—";
            String etaStr = "—";

            if (duration > 0) {
              final bytesPerSec = received / duration;
              speedStr = _formatSpeed(bytesPerSec);
              
              final remainingBytes = total - received;
              final secondsLeft = remainingBytes / bytesPerSec;
              etaStr = _formatETA(secondsLeft.toInt());
            }

            activeDownloads[item.id] = activeDownloads[item.id]!.copyWith(
              progress: progress,
              speed: speedStr,
              eta: etaStr,
              size: "${(total / (1024 * 1024)).toStringAsFixed(1)} MB",
            );
          }
        },
      );

      // Successfully Completed
      final completed = activeDownloads[item.id]!.copyWith(
        status: DownloadStatus.completed,
        progress: 100,
        filePath: savePath,
      );
      
      completedDownloads.add(completed);
      activeDownloads.remove(item.id);
      _checkQueue();

    } catch (e) {
      print("[DownloadService] Error: $e");
      final failed = (activeDownloads[item.id] ?? item).copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString()
      );
      failedDownloads.add(failed);
      activeDownloads.remove(item.id);
      _checkQueue();
    }
  }

  void _checkQueue() {
    if (queue.isNotEmpty && activeDownloads.length < _maxConcurrent) {
      final next = queue.removeAt(0);
      _executeDownload(next);
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      
      // Handle Android 13+ (Photos/Videos)
      final statusVideos = await Permission.videos.request();
      return statusVideos.isGranted;
    }
    return true;
  }

  Future<String> _getPublicSavePath(String title, String format) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/VidGet');
    } else {
      dir = await getDownloadsDirectory();
    }

    if (dir != null && !await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Clean filename
    final safeTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    return p.join(dir!.path, "${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.$format");
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return "${bytesPerSec.toStringAsFixed(0)} B/s";
    if (bytesPerSec < 1024 * 1024) return "${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s";
    return "${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s";
  }

  String _formatETA(int seconds) {
    if (seconds < 60) return "${seconds}s";
    final minutes = (seconds / 60).floor();
    final remainingSec = seconds % 60;
    return "${minutes}m ${remainingSec}s";
  }
}
