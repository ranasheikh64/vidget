import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:flutter/foundation.dart';
import '../models/video_item_model.dart';
import '../models/video_format_model.dart';

class ExtractorService extends GetxService {
  final _yt = yt.YoutubeExplode();
  final _dio = Dio();
  
  // Pagination & Cache
  yt.VideoSearchList? _currentSearchList;
  int _currentImagePage = 1;
  String _lastImageQuery = "";
  final Map<String, List<VideoFormat>> _formatCache = {};


  @override
  void onClose() {
    _yt.close();
    super.onClose();
  }

  // Real-time Search Logic
  Future<List<VideoItem>> search(String query, {int limit = 15}) async {
    print("[Scraper] Initiating background search for: $query");
    try {
      _currentSearchList = await _yt.search.getVideos(query);
      
      // Revert compute to direct mapping because YouTube objects contain unsendable internal state
      return _mapYoutubeResults(_currentSearchList!);
    } catch (e) {
      print("[Scraper] Search error: $e");
      return [];
    }
  }

  Future<List<VideoItem>> fetchMoreVideos() async {
    if (_currentSearchList == null) return [];
    
    try {
      final nextList = await _currentSearchList!.nextPage();
      if (nextList == null) return [];
      _currentSearchList = nextList;
      
      return _mapYoutubeResults(nextList);
    } catch (e) {
      print("[Scraper] Error loading more videos: $e");
      return [];
    }
  }

  // Map YouTube results directly (Isolates crash with SearchList internal objects)
  List<VideoItem> _mapYoutubeResults(Iterable<yt.Video> list) {
    return list.map((video) => VideoItem(
      id: video.id.value.hashCode + DateTime.now().microsecondsSinceEpoch,
      title: video.title,
      channel: video.author,
      views: _formatViews(video.engagement.viewCount),
      duration: video.duration?.toString().split('.').first ?? "0:00",
      quality: "HD",
      thumb: video.thumbnails.highResUrl,
      videoUrl: "https://www.youtube.com/watch?v=${video.id.value}",
      idString: video.id.value,
      isLive: video.isLive,
    )).toList();
  }

  String _formatViews(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // Category specific logic
  Future<List<VideoItem>> getCategoryVideos(String categoryId) async {
    _currentSearchList = null;
    _currentImagePage = 1;
    
    String query = "";
    switch (categoryId) {
      case 'trending': query = "trending now"; break;
      case 'movies': query = "full length movie 2024"; break;
      case 'music': query = "official music video trending"; break;
      case 'sports': query = "sports highlights today"; break;
      case 'news': query = "breaking news live world"; break;
      case 'live': query = "live stream now"; break;
      case 'images': 
        _lastImageQuery = "wallpaper luxury nature";
        return await fetchImages(_lastImageQuery);
      default: 
        _lastImageQuery = categoryId;
        query = categoryId;
    }
    return await search(query);
  }

  // Unsplash Image Scraping - ISOLATE OPTIMIZED
  Future<List<VideoItem>> fetchImages(String query, {int page = 1}) async {
    try {
      final url = "https://unsplash.com/s/photos/${Uri.encodeComponent(query)}?page=$page";
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
          },
        ),
      );
      
      // Offload HTML Parsing to Compute (Safe because it's just a String)
      final items = await compute(_parseUnsplashHtml, response.data.toString());
      _currentImagePage = page;
      return items;
    } catch (e) {
      print("[Scraper] Image scraping error: $e");
      return [];
    }
  }

  static List<VideoItem> _parseUnsplashHtml(String htmlData) {
    final document = html.parse(htmlData);
    final images = document.querySelectorAll('img');
    List<VideoItem> items = [];
    
    for (var img in images) {
      final src = img.attributes['src'];
      final alt = img.attributes['alt'] ?? "Beautiful Image";
      
      if (src != null && src.contains('images.unsplash.com') && items.length < 25) {
        items.add(VideoItem(
          id: src.hashCode + DateTime.now().microsecondsSinceEpoch,
          title: alt,
          channel: "Unsplash",
          views: "High Res",
          duration: "IMG",
          quality: "4K",
          thumb: src,
          videoUrl: src,
          idString: src,
        ));
      }
    }
    return items;
  }

  Future<List<VideoItem>> fetchMoreImages() async {
    return await fetchImages(_lastImageQuery, page: _currentImagePage + 1);
  }

  // Video/Formats Extraction Logic
  Future<List<VideoFormat>> getAvailableFormats(String url) async {
    if (_formatCache.containsKey(url)) {
      print("[ExtractorService] Returning cached formats for: $url");
      return _formatCache[url]!;
    }

    List<VideoFormat> formats = [];
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      formats = await _getYoutubeFormats(url);
    } else {
      formats = await _getGenericFormats(url);
    }

    if (formats.isNotEmpty) {
      _formatCache[url] = formats;
    }
    return formats;
  }

  bool hasCachedFormats(String url) => _formatCache.containsKey(url);


  Future<List<VideoFormat>> _getYoutubeFormats(String url) async {
    try {
      final videoId = yt.VideoId.parseVideoId(url);
      if (videoId == null) return [];
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      List<VideoFormat> formats = [];

      // 1. Muxed Streams (Video + Audio) - Best for simple download
      for (var stream in manifest.muxed) {
        formats.add(VideoFormat(
          quality: stream.videoQualityLabel,
          extension: stream.container.name,
          sizeBytes: stream.size.totalBytes,
          url: stream.url.toString(),
          isAudioOnly: false,
          videoCodec: stream.videoCodec,
          tag: stream.tag,
        ));
      }

      // 2. Audio Only
      final bestAudio = manifest.audioOnly.withHighestBitrate();
      formats.add(VideoFormat(
        quality: "Audio (High Quality)",
        extension: bestAudio.container.name,
        sizeBytes: bestAudio.size.totalBytes,
        url: bestAudio.url.toString(),
        isAudioOnly: true,
        audioCodec: bestAudio.audioCodec,
        tag: bestAudio.tag,
      ));

      return formats;
    } catch (e) {
      print("[ExtractorService] YT Formats error: $e");
      return [];
    }
  }

  Future<List<VideoFormat>> _getGenericFormats(String url) async {
    // For non-youtube, we usually only have one URL detected from meta tags
    final item = await extract(url);
    if (item != null && item.videoUrl != null) {
      return [
        VideoFormat(
          quality: item.quality,
          extension: "mp4",
          url: item.videoUrl!,
          isAudioOnly: false,
          tag: 0,
        )
      ];
    }
    return [];
  }

  // URL Extraction Logic
  Future<VideoItem?> extract(String url) async {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return await _extractYoutube(url);
    } else {
      return await _extractGeneric(url);
    }
  }

  Future<VideoItem?> _extractYoutube(String url) async {
    try {
      final video = await _yt.videos.get(url);
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final streamInfo = manifest.muxed.withHighestBitrate();

      return VideoItem(
        id: DateTime.now().millisecondsSinceEpoch,
        title: video.title,
        channel: video.author,
        views: _formatViews(video.engagement.viewCount),
        duration: video.duration?.toString().split('.').first ?? "0:00",
        quality: streamInfo.videoQualityLabel,
        thumb: video.thumbnails.highResUrl,
        videoUrl: streamInfo.url.toString(),
        idString: video.id.value,
        isLive: video.isLive,
      );
    } catch (e) {
      print("[Scraper] YT Extraction error: $e");
      return null;
    }
  }

  Future<VideoItem?> _extractGeneric(String url) async {
    try {
      final response = await _dio.get(url);
      
      // Offload Generic Meta Parsing to Compute
      return await compute(_parseGenericMeta, {
        "html": response.data.toString(),
        "url": url,
      });
    } catch (e) {
      print("[Scraper] Generic Extraction error: $e");
      return null;
    }
  }

  static VideoItem? _parseGenericMeta(Map<String, dynamic> data) {
    final document = html.parse(data["html"] as String);
    final url = data["url"] as String;

    final title = document.querySelector('meta[property="og:title"]')?.attributes['content'] ?? 
                  document.querySelector('meta[name="title"]')?.attributes['content'] ?? 
                  document.querySelector('title')?.text ?? "Unknown Video";
    
    final thumb = document.querySelector('meta[property="og:image"]')?.attributes['content'] ?? 
                  document.querySelector('meta[name="twitter:image"]')?.attributes['content'] ?? "";
    
    var videoUrl = document.querySelector('meta[property="og:video:url"]')?.attributes['content'] ?? 
                     document.querySelector('meta[property="og:video:secure_url"]')?.attributes['content'] ??
                     document.querySelector('meta[property="og:video"]')?.attributes['content'];

    // Fallback for some adult sites that don't follow OG tags perfectly
    if (videoUrl == null) {
      final scripts = document.querySelectorAll('script');
      for (var script in scripts) {
        final content = script.text;
        if (content.contains('videoUrl') || content.contains('video_url')) {
          // Attempt to find a URL-like string in the script content
          final regex = RegExp(r'https?://[^\s\"'']+\.mp4');
          final match = regex.firstMatch(content);
          if (match != null) {
            videoUrl = match.group(0);
            break;
          }
        }
      }
    }

    final siteName = document.querySelector('meta[property="og:site_name"]')?.attributes['content'] ?? 
                     document.querySelector('meta[name="application-name"]')?.attributes['content'] ??
                     Uri.parse(url).host;

    if (title == "Unknown Video" && videoUrl == null) return null;

    return VideoItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      channel: siteName,
      views: "Direct Link",
      duration: "—",
      quality: "HD",
      thumb: thumb,
      videoUrl: videoUrl,
      idString: videoUrl ?? url,
    );
  }
}
