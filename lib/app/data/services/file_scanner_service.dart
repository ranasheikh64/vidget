import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

enum FileCategory { all, videos, audio, images, docs }

class ScannedFile {
  final String path;
  final String name;
  final String extension;
  final FileCategory category;
  final int size;
  final DateTime modified;
  final String? thumbnailPath;

  ScannedFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.category,
    required this.size,
    required this.modified,
    this.thumbnailPath,
  });

  String get sizeStr {
    if (size < 1024) return "${size} B";
    if (size < 1024 * 1024) return "${(size / 1024).toStringAsFixed(1)} KB";
    if (size < 1024 * 1024 * 1024) return "${(size / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  String get thumb {
    switch (category) {
      case FileCategory.videos: return "🎬";
      case FileCategory.audio: return "🎵";
      case FileCategory.images: return "🖼️";
      case FileCategory.docs: return "📄";
      default: return "📁";
    }
  }
}

class FileScannerService extends GetxService {
  final RxList<ScannedFile> allFiles = <ScannedFile>[].obs;
  final RxBool isScanning = false.obs;

  final videoExt = ['.mp4', '.mkv', '.mov', '.avi', '.wmv'];
  final audioExt = ['.mp3', '.m4a', '.wav', '.ogg', '.flac'];
  final imageExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  final docExt = ['.pdf', '.doc', '.docx', '.txt', '.srt'];

  Future<FileScannerService> init() async {
    return this;
  }

  Future<void> scanStorage() async {
    if (isScanning.value) return;
    isScanning.value = true;
    allFiles.clear();

    try {
      // Request permissions
      if (Platform.isAndroid) {
        if (!await _requestPermissions()) {
          isScanning.value = false;
          return;
        }
      }

      List<Directory> scanDirs = [];
      
      if (Platform.isAndroid) {
        // Common public directories
        final external = await getExternalStorageDirectories();
        if (external != null) {
          for (var dir in external) {
            // Get the root of external storage by going up until we find the base
            // Or just use common paths
            String path = dir.path;
            int androidIndex = path.indexOf('/Android');
            if (androidIndex != -1) {
              String root = path.substring(0, androidIndex);
              scanDirs.add(Directory(root)); // Scans the whole user storage
            }
          }
        }
        
        // Also add the app's specific directories
        final appDoc = await getApplicationDocumentsDirectory();
        scanDirs.add(appDoc);
      } else {
        final appDoc = await getApplicationDocumentsDirectory();
        scanDirs.add(appDoc);
      }

      for (var dir in scanDirs) {
        if (await dir.exists()) {
          await _listDir(dir);
        }
      }
    } catch (e) {
      print("Scan Error: $e");
    } finally {
      isScanning.value = false;
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;
    
    // For Android 13+
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    
    return statuses.values.every((s) => s.isGranted);
  }

  Future<void> _listDir(Directory dir) async {
    try {
      final List<FileSystemEntity> entities = await dir.list(recursive: false, followLinks: false).toList();
      
      for (var entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          FileCategory? category;
          
          if (videoExt.contains(ext)) category = FileCategory.videos;
          else if (audioExt.contains(ext)) category = FileCategory.audio;
          else if (imageExt.contains(ext)) category = FileCategory.images;
          else if (docExt.contains(ext)) category = FileCategory.docs;
          
          if (category != null) {
            final stat = await entity.stat();
            String? thumb;
            
            // For images, the file itself is the thumbnail
            if (category == FileCategory.images) {
              thumb = entity.path;
            } else if (category == FileCategory.videos) {
              // Videos will have thumbnails generated asynchronously or on-demand
              // For now, we'll try to generate it during scan for a better first impression
              thumb = await _generateVideoThumbnail(entity.path);
            }

            allFiles.add(ScannedFile(
              path: entity.path,
              name: p.basename(entity.path),
              extension: ext,
              category: category,
              size: stat.size,
              modified: stat.modified,
              thumbnailPath: thumb,
            ));
          }
        } else if (entity is Directory) {
          // Skip Android system folders or hidden folders to keep it fast
          final name = p.basename(entity.path);
          if (name.startsWith('.') || name == 'Android') continue;
          
          await _listDir(entity);
        }
      }
    } catch (e) {
      // Access denied for some folders, just skip
    }
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 250, 
        quality: 75,
      );
      return thumbPath;
    } catch (e) {
      print("Thumbnail Error: $e");
      return null;
    }
  }
}
