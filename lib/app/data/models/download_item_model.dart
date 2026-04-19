enum DownloadStatus { downloading, paused, completed, failed, queued }

class DownloadItem {
  final int id;
  final String title;
  final String site;
  final String format;
  final String quality;
  final String size;
  final double progress;
  final String speed;
  final String eta;
  final DownloadStatus status;
  final String icon;

  final String? url;
  final String? filePath;
  final String? errorMessage;
  final String? timestamp;

  DownloadItem({
    required this.id,
    required this.title,
    required this.site,
    required this.format,
    required this.quality,
    required this.size,
    required this.progress,
    required this.speed,
    required this.eta,
    required this.status,
    required this.icon,
    this.url,
    this.filePath,
    this.errorMessage,
    this.timestamp,
  });

  DownloadItem copyWith({
    int? id,
    String? title,
    String? site,
    String? format,
    String? quality,
    String? size,
    double? progress,
    String? speed,
    String? eta,
    DownloadStatus? status,
    String? icon,
    String? url,
    String? filePath,
    String? errorMessage,
    String? timestamp,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      site: site ?? this.site,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      size: size ?? this.size,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
