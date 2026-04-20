import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(DownloadHandlerTask());
}

class DownloadHandlerTask extends TaskHandler {
  yt.YoutubeExplode? _yt;
  SendPort? _sendPort;
  
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _yt = yt.YoutubeExplode();
    print("[DownloadHandlerTask] Started at $timestamp");

    // Defensive delay to ensure platform channels are initialized in the isolate
    await Future.delayed(const Duration(milliseconds: 500));

    // Fetch arguments from shared data in v6.x
    final videoUrl = await FlutterForegroundTask.getData<String>(key: 'video_url');
    final savePath = await FlutterForegroundTask.getData<String>(key: 'save_path');
    final title = await FlutterForegroundTask.getData<String>(key: 'title');
    final videoId = await FlutterForegroundTask.getData<int>(key: 'video_id');
    final itag = await FlutterForegroundTask.getData<int>(key: 'itag');

    if (videoUrl != null && savePath != null && videoId != null) {
      _downloadVideo(videoUrl, savePath, title ?? "Video", videoId, itag);
    } else {
      print("[DownloadHandlerTask] Missing arguments, stopping task.");
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    _sendPort = sendPort;
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    _yt?.close();
    print("[DownloadHandlerTask] Destroyed at $timestamp");
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("[DownloadHandlerTask] Notification button pressed: $id");
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/");
    print("[DownloadHandlerTask] Notification pressed");
  }

  Future<void> _downloadVideo(String videoUrl, String savePath, String title, int videoId, int? itag) async {
    try {
      print("[DownloadHandlerTask] Starting download: $title to $savePath");
      
      final video = await _yt!.videos.get(videoUrl);
      final manifest = await _yt!.videos.streamsClient.getManifest(video.id);
      
      yt.StreamInfo streamInfo;
      if (itag != null) {
        streamInfo = manifest.streams.firstWhere((s) => s.tag == itag);
      } else {
        streamInfo = manifest.muxed.withHighestBitrate();
      }

      final totalSize = streamInfo.size.totalBytes;
      var downloaded = 0;

      final file = File(savePath);
      if (await file.exists()) await file.delete();
      
      final stream = _yt!.videos.streamsClient.get(streamInfo);
      final iosSink = file.openWrite();

      await for (final data in stream) {
        iosSink.add(data);
        downloaded += data.length;
        
        final progress = (downloaded / totalSize * 100).toInt();
        
        // Update notification
        FlutterForegroundTask.updateService(
          notificationTitle: "Downloading: $title",
          notificationText: "$progress% complete",
        );

        // Notify main isolate via SendPort in v6.x
        _sendPort?.send({
          'video_id': videoId,
          'progress': progress.toDouble(),
          'status': 'downloading',
          'title': title,
        });
      }

      await iosSink.close();
      
      print("[DownloadHandlerTask] Download Complete: $title");
      
      _sendPort?.send({
        'video_id': videoId,
        'progress': 100.0,
        'status': 'completed',
        'title': title,
      });
      
    } catch (e) {
      print("[DownloadHandlerTask] Download Error: $e");
      _sendPort?.send({
        'video_id': videoId,
        'progress': 0.0,
        'status': 'failed',
        'error': e.toString(),
      });
    }
  }
}
