class VideoItem {
  final int id;
  final String title;
  final String channel;
  final String views;
  final String duration;
  final String quality;
  final String thumb;
  final String? videoUrl;
  final String? format;
  final bool isLive;

  VideoItem({
    required this.id,
    required this.title,
    required this.channel,
    required this.views,
    required this.duration,
    required this.quality,
    required this.thumb,
    this.videoUrl,
    this.format,
    this.isLive = false,
  });

  VideoItem copyWith({
    int? id,
    String? title,
    String? channel,
    String? views,
    String? duration,
    String? quality,
    String? thumb,
    String? videoUrl,
    String? format,
    bool? isLive,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      channel: channel ?? this.channel,
      views: views ?? this.views,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      thumb: thumb ?? this.thumb,
      videoUrl: videoUrl ?? this.videoUrl,
      format: format ?? this.format,
      isLive: isLive ?? this.isLive,
    );
  }
}
