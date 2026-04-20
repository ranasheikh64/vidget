import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vidget/app/data/services/download_handler_task.dart';
import 'package:vidget/app/data/models/download_item_model.dart';
import 'package:vidget/app/data/models/video_item_model.dart';
import 'package:vidget/app/data/models/video_format_model.dart';

class DownloadService extends GetxService {
  final activeDownloads = <int, DownloadItem>{}.obs;
  final taskIdToVideoId = <String, int>{};
  final completedDownloads = <DownloadItem>[].obs;
  final failedDownloads = <DownloadItem>[].obs;
  
  // Global visibility observables
  final lastActiveProgress = 0.0.obs;
  final lastActiveTitle = "".obs;
  final isGlobalProgressVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupDownloader();
    _initForegroundTask();
  }

  Future<DownloadService> init() async {
    return this;
  }

  void _setupDownloader() {
    // Keep background_downloader for non-streaming links if necessary
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        _handleStatusUpdate(update.task, update.status);
      } else if (update is TaskProgressUpdate) {
        _handleProgressUpdate(update.task, update.progress);
      }
    });
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vidget_download_channel',
        channelName: 'VidGet Downloads',
        channelDescription: 'Foreground service for robust video downloading',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // Register port listener for updates from background
    FlutterForegroundTask.receivePort?.listen(_onReceiveTaskData);
  }

  void _onReceiveTaskData(dynamic data) {
    if (data is Map<dynamic, dynamic>) {
      final int videoId = data['video_id'];
      final double progress = (data['progress'] as num).toDouble();
      final String status = data['status'];
      final String title = data['title'];

      final currentItem = activeDownloads[videoId];
      if (currentItem == null) return;

      DownloadStatus appStatus = DownloadStatus.downloading;
      if (status == 'completed') appStatus = DownloadStatus.completed;
      if (status == 'failed') appStatus = DownloadStatus.failed;

      final updated = currentItem.copyWith(
        progress: progress,
        status: appStatus,
      );

      if (appStatus == DownloadStatus.completed) {
        completedDownloads.add(updated);
        activeDownloads.remove(videoId);
        isGlobalProgressVisible.value = false;
        Get.snackbar("Download Complete", title, snackPosition: SnackPosition.BOTTOM);
        _maybeStopForegroundService();
      } else if (appStatus == DownloadStatus.failed) {
        failedDownloads.add(updated);
        activeDownloads.remove(videoId);
        isGlobalProgressVisible.value = false;
        Get.snackbar("Download Failed", title, snackPosition: SnackPosition.BOTTOM);
        _maybeStopForegroundService();
      } else {
        activeDownloads[videoId] = updated;
        lastActiveProgress.value = progress;
        lastActiveTitle.value = title;
        isGlobalProgressVisible.value = true;
      }
      
      activeDownloads.refresh();
    }
  }

  void _maybeStopForegroundService() {
    if (activeDownloads.isEmpty) {
      FlutterForegroundTask.stopService();
    }
  }

  void _handleStatusUpdate(Task task, TaskStatus status) {
    // (Legacy handler for non-streaming tasks)
    final videoId = taskIdToVideoId[task.taskId];
    if (videoId == null) return;
    _handleGenericStatusUpdate(videoId, status, task.taskId);
  }

  void _handleProgressUpdate(Task task, double progress) {
    // (Legacy handler for non-streaming tasks)
    final videoId = taskIdToVideoId[task.taskId];
    if (videoId == null) return;
    final progressValue = (progress >= 0 ? progress * 100 : 0).toDouble();
    _updateProgress(videoId, progressValue);
  }

  void _handleGenericStatusUpdate(int videoId, TaskStatus status, String taskId) {
    final currentItem = activeDownloads[videoId];
    if (currentItem == null) return;

    DownloadStatus appStatus = DownloadStatus.downloading;
    switch (status) {
      case TaskStatus.enqueued: appStatus = DownloadStatus.queued; break;
      case TaskStatus.complete: appStatus = DownloadStatus.completed; break;
      case TaskStatus.failed:
      case TaskStatus.canceled:
      case TaskStatus.notFound: appStatus = DownloadStatus.failed; break;
      default: appStatus = DownloadStatus.downloading;
    }

    final updated = currentItem.copyWith(status: appStatus);
    if (appStatus == DownloadStatus.completed || appStatus == DownloadStatus.failed) {
      if (appStatus == DownloadStatus.completed) completedDownloads.add(updated);
      else failedDownloads.add(updated);
      activeDownloads.remove(videoId);
      taskIdToVideoId.remove(taskId);
      isGlobalProgressVisible.value = false;
    } else {
      activeDownloads[videoId] = updated;
    }
    activeDownloads.refresh();
  }

  void _updateProgress(int videoId, double progress) {
    final currentItem = activeDownloads[videoId];
    if (currentItem == null) return;
    final updated = currentItem.copyWith(progress: progress, status: DownloadStatus.downloading);
    activeDownloads[videoId] = updated;
    lastActiveProgress.value = progress;
    lastActiveTitle.value = updated.title;
    isGlobalProgressVisible.value = true;
    activeDownloads.refresh();
  }

  Future<void> startDownload(VideoItem video, VideoFormat format) async {
    if (!await _checkPermission()) {
      Get.snackbar("Permission Denied", "Storage access is required to download videos.");
      return;
    }

    final String fileName = "${video.title.replaceAll(RegExp(r'[^\w\s\-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.${format.extension}";
    final String savePath = await _getSavePath(fileName);

    // Register active download in UI
    activeDownloads[video.id] = DownloadItem(
      id: video.id,
      title: video.title,
      site: video.channel,
      format: format.extension.toUpperCase(),
      quality: format.quality,
      size: format.sizeLabel,
      progress: 0,
      speed: "—",
      eta: "—",
      status: DownloadStatus.queued,
      icon: "📥",
      url: format.url,
    );
    activeDownloads.refresh();

    // Save download info to shared data (v6 path)
    await FlutterForegroundTask.saveData(key: 'video_url', value: 'https://www.youtube.com/watch?v=${video.idString}');
    await FlutterForegroundTask.saveData(key: 'save_path', value: savePath);
    await FlutterForegroundTask.saveData(key: 'title', value: video.title);
    await FlutterForegroundTask.saveData(key: 'video_id', value: video.id);
    await FlutterForegroundTask.saveData(key: 'itag', value: format.tag);

    // Launch robust streaming downloader via Foreground Service
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Initializing Download...',
        notificationText: video.title,
        callback: startCallback,
      );
    }

    Get.snackbar("Download Started", video.title, snackPosition: SnackPosition.BOTTOM);
  }

  Future<String> _getSavePath(String fileName) async {
    final dir = await getPublicDownloadsDir();
    return "${dir.path}/$fileName";
  }

  Future<Directory> getPublicDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/VidGet');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } else {
      // Fallback for iOS or other
      final dir = await getApplicationDocumentsDirectory();
      return dir;
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      
      final statusVideos = await Permission.videos.request();
      if (statusVideos.isGranted) return true;

      final statusPhotos = await Permission.photos.request();
      if (statusPhotos.isGranted) return true;
      
      return false;
    }
    return true;
  }
}
