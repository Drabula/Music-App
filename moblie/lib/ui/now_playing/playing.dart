import 'dart:math';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/model/song.dart';
import 'audio_player_manager.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.playingSong, required this.songs});

  final Song playingSong;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(
      songs: songs,
      playingSong: playingSong,
    );
  }
}

enum RepeatMode { off, one, all }

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,
  });

  final Song playingSong;
  final List<Song> songs;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  late double _currentAnimationPosition = 0.0;
  bool _isShuffle = false;

  RepeatMode _repeatMode = RepeatMode.off;
  @override
  void initState() {
    super.initState();
    _currentAnimationPosition = 0.0;
    _song = widget.playingSong;
    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _audioPlayerManager = AudioPlayerManager(songUrl: _song.source);
    _audioPlayerManager.init();
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _audioPlayerManager.player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });
  }
  void _handleSongCompletion() {
    if (_repeatMode == RepeatMode.one) {
      _audioPlayerManager.player.seek(Duration.zero);
      _audioPlayerManager.player.play();
    } else {
      _setNextSong();
      if (_repeatMode == RepeatMode.all && _selectedItemIndex == 0) {
        _audioPlayerManager.player.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = 64;
    final radius = (screenWidth - delta) / 2;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Now Playing',
        ),
        backgroundColor: Colors.lightBlue,
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.lightBlueAccent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      _song.album,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0)
                          .animate(_imageAnimController),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/itunes.jpg',
                          image: _song.image,
                          width: screenWidth - delta,
                          height: screenWidth - delta,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/itunes.jpg',
                              width: screenWidth - delta,
                              height: screenWidth - delta,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _song.artist,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _progressBar(),
                    const SizedBox(height: 32),
                    _mediaButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayerManager.dispose();
    _imageAnimController.dispose();
    super.dispose();
  }

  Widget _mediaButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        MediaButtonControl(
            function: _setShuffle,
            icon: Icons.shuffle,
            color: _getShuffleColor(),
            size: 24),
        MediaButtonControl(
            function: _setPrevSong,
            icon: Icons.skip_previous,
            color: Colors.white,
            size: 36),
        _playButton(),
        MediaButtonControl(
            function: _setNextSong,
            icon: Icons.skip_next,
            color: Colors.white,
            size: 36),
        MediaButtonControl(
            function: _cycleRepeatMode,
            icon: _getRepeatIcon(),
            color: _getRepeatColor(),
            size: 24),
      ],
    );
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 5.0,
          barCapShape: BarCapShape.round,
          baseBarColor: Colors.grey.withOpacity(0.3),
          progressBarColor: Colors.purple,
          bufferedBarColor: Colors.grey.withOpacity(0.3),
          thumbColor: Colors.purple,
          thumbGlowColor: Colors.purple.withOpacity(0.3),
          thumbRadius: 10.0,
        );
      },
    );
  }

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playState = snapshot.data;
        final processingState = playState?.processingState;
        final playing = playState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          _pauseRotationAnim();
          return Container(
            margin: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.play();
            },
            icon: Icons.play_arrow,
            color: Colors.white,
            size: 48,
          );
        } else if (processingState != ProcessingState.completed) {
          _playRotationAnim();
          return MediaButtonControl(
              function: () {
                _audioPlayerManager.player.pause();
                _pauseRotationAnim();
              },
              icon: Icons.pause,
              color: Colors.white,
              size: 48);
        } else {
          if (processingState == ProcessingState.completed) {
            _stopRotationAnim();
            _resetRotationAnim();
          }
          return MediaButtonControl(
              function: () {
                _audioPlayerManager.player.seek(Duration.zero);
                _resetRotationAnim();
                _playRotationAnim();
              },
              icon: Icons.replay,
              color: Colors.white,
              size: 48);
        }
      },
    );
  }

  void _cycleRepeatMode() {
    setState(() {
      if (_repeatMode == RepeatMode.off) {
        _repeatMode = RepeatMode.one;
      } else if (_repeatMode == RepeatMode.one) {
        _repeatMode = RepeatMode.all;
      } else {
        _repeatMode = RepeatMode.off;
      }
    });
  }

  IconData _getRepeatIcon() {
    switch (_repeatMode) {
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat;
      default:
        return Icons.repeat;
    }
  }

  Color   _getRepeatColor() {
    switch (_repeatMode) {
      case RepeatMode.off:
        return Colors.grey;
      case RepeatMode.one:
      case RepeatMode.all:
        return Colors.white;
      default:
        return Colors.grey;
    }
  }


  void _setShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  Color? _getShuffleColor() {
    return _isShuffle ? Colors.deepPurple : Colors.grey;
  }

  void _setNextSong() {
    if (_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else {
      ++_selectedItemIndex;
    }
    if (_selectedItemIndex >= widget.songs.length) {
      _selectedItemIndex = _selectedItemIndex % widget.songs.length;
    }
    final nextSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _resetRotationAnim();
    setState(() {
      _song = nextSong;
    });
  }

  void _setPrevSong() {
    if (_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else {
      --_selectedItemIndex;
    }
    if (_selectedItemIndex < 0) {
      _selectedItemIndex = (-1 * _selectedItemIndex) % widget.songs.length;
    }
    final nextSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _resetRotationAnim();
    setState(() {
      _song = nextSong;
    });
  }

  void _playRotationAnim() {
    _imageAnimController.forward(from: _currentAnimationPosition);
    _imageAnimController.repeat();
  }

  void _pauseRotationAnim() {
    _stopRotationAnim();
    _currentAnimationPosition = _imageAnimController.value;
  }

  void _stopRotationAnim() {
    _imageAnimController.stop();
  }

  void _resetRotationAnim() {
    _currentAnimationPosition = 0.0;
    _imageAnimController.value = _currentAnimationPosition;
  }
}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;

  @override

  State<StatefulWidget> createState() => _MediaButtonControlState();
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: function,
      icon: Icon(icon),
      iconSize: size,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.function,
      icon: Icon(widget.icon),
      iconSize: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
