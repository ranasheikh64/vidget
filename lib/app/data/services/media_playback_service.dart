import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pod_player/pod_player.dart';
import '../models/video_item_model.dart';
import 'extractor_service.dart';

class MediaPlaybackService extends GetxService {
  late AudioHandler _audioHandler;
  final _player = AudioPlayer();

  final isPlaying = false.obs;
  final currentPath = ''.obs;

  Future<MediaPlaybackService> init() async {
    _audioHandler = await AudioService.init(
      builder: () => BackgroundAudioHandler(_player),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.vidget.playback',
        androidNotificationChannelName: 'VidGet Playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: true,
      ),
    );

    // Configure Audio Session for background playback durability
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle interruptions (calls, other apps)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck ||
            event.type == AudioInterruptionType.pause) {
          pause();
        }
      } else {
        if (event.type == AudioInterruptionType.pause ||
            event.type == AudioInterruptionType.duck) {
          resume();
        }
      }
    });

    return this;
  }

  Future<void> playFile(String path, String title) async {
    currentPath.value = path;

    // Set metadata for notification
    final mediaItem = MediaItem(
      id: path,
      album: "VidGet Downloads",
      title: title,
      artist: "VidGet Player",
      extras: {'url': path},
    );

    _audioHandler.addQueueItem(mediaItem);
    await _audioHandler.playMediaItem(mediaItem);
    isPlaying.value = true;
  }

  Future<void> pause() async => await _audioHandler.pause();
  Future<void> resume() async => await _audioHandler.play();
  Future<void> stop() async {
    await _audioHandler.stop();
    isPlaying.value = false;
    currentPath.value = '';
  }

  Future<void> syncWithVideo(
    PodPlayerController? videoController,
    VideoItem item,
  ) async {
    if (videoController == null) return;

    print("[MediaPlaybackService] Resolving stream for: ${item.title}");
    
    // Resolve raw stream URL for YouTube to prevent ExoPlayer "UnrecognizedInputFormatException"
    String streamUrl = item.videoUrl ?? "https://www.youtube.com/watch?v=${item.idString}";
    
    if (streamUrl.contains('youtube.com') || streamUrl.contains('youtu.be')) {
      try {
        final extractor = Get.find<ExtractorService>();
        final formats = await extractor.getAvailableFormats(streamUrl);
        if (formats.isNotEmpty) {
          // Use the highest quality audio-only or muxed stream
          final bestAudio = formats.firstWhere((f) => f.isAudioOnly, orElse: () => formats.first);
          streamUrl = bestAudio.url;
          print("[MediaPlaybackService] Stream resolved: ${bestAudio.quality}");
        }
      } catch (e) {
        print("[MediaPlaybackService] Stream resolution error: $e");
      }
    }

    final mediaItem = MediaItem(
      id: streamUrl,
      album: "VidGet Live",
      title: item.title,
      artist: item.channel,
      duration: videoController.totalVideoLength,
      artUri: Uri.tryParse(item.thumb),
      extras: {'originalUrl': item.videoUrl},
    );

    _audioHandler.addQueueItem(mediaItem);
    await _audioHandler.updateMediaItem(mediaItem);

    // Start background playback with the resolved stream
    await _audioHandler.playMediaItem(mediaItem);
  }
}

class BackgroundAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  BackgroundAudioHandler(this._player) {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    try {
      if (mediaItem.id.startsWith('http')) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
      } else {
        await _player.setAudioSource(AudioSource.uri(Uri.file(mediaItem.id)));
      }
      _player.play();
    } catch (e) {
      print("Playback Error: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
