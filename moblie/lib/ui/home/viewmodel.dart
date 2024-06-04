import 'dart:async';

import 'package:moblie/data/repository/repository.dart';
import 'package:moblie/ui/home/home.dart';

import '../../data/model/song.dart';

class MusicAppViewModel {
  StreamController<List<Song>> songStream = StreamController();

  void loadSong() {
    final repository = DefaultRepository();
    repository.loadData().then((value) => songStream.add(value!));
  }
}

