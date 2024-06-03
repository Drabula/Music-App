import 'dart:convert';
import '../model/song.dart';
import 'package:http/http.dart' as http;

abstract interface class Datasource {
  Future<List<Song>?> loadData();
}

class RemoteDataSource implements Datasource {
  @override
  Future<List<Song>?> loadData() async {
    final url = 'https://thantrieu.com/resources/braniumapis/songs.json';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final bodyContent = utf8.decode(response.bodyBytes);
      var songWrapper = jsonDecode(bodyContent) as Map;
      var songList = songWrapper['songs'] as List;
      List<Song> songs = songList.map((song) => Song.fromJson(song)).toList();
    } else {
      return null;
    }
  }
}

class LocalDataSource implements Datasource {
  @override
  Future<List<Song>?> loadData() {
    // TODO: implement loadData
    throw UnimplementedError();
  }
}
