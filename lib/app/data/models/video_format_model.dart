class VideoFormat {
  final String quality;
  final String extension;
  final int? sizeBytes;
  final String url;
  final bool isAudioOnly;
  final String? videoCodec;
  final String? audioCodec;
  final int tag;

  VideoFormat({
    required this.quality,
    required this.extension,
    this.sizeBytes,
    required this.url,
    this.isAudioOnly = false,
    this.videoCodec,
    this.audioCodec,
    required this.tag,
  });

  String get sizeLabel {
    if (sizeBytes == null || sizeBytes == 0) return "-- MB";
    final mb = sizeBytes! / (1024 * 1024);
    return "${mb.toStringAsFixed(1)} MB";
  }

  @override
  String toString() {
    return 'VideoFormat(quality: $quality, extension: $extension, size: $sizeLabel, isAudioOnly: $isAudioOnly)';
  }
}
