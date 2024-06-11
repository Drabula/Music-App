import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  @override
  _DiscoveryTabState createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  List<Map<String, String>> musicNews = [];

  @override
  void initState() {
    super.initState();
    fetchMusicNews();
  }

  Future<void> fetchMusicNews() async {
    final response = await http.get(Uri.parse('https://www.billboard.com/charts/hot-100/'));

    if (response.statusCode == 200) {
      var document = html.parse(response.body);
      var elements = document.querySelectorAll('.o-chart-results-list-row-container');// css từ cấu trúc html của web

      List<Map<String, String>> fetchedNews = []; //Danh sách này chứa các bài hát và nghệ sĩ được lấy từ trang Billboard.

      for (var element in elements) {
        final titleElement = element.querySelector('h3');
        final artistElement = element.querySelector('h3 + span');
        final imageElement = element.querySelector('img'); //Nếu ảnh tồn tại, URL của ảnh được lưu vào biến imageUrl

        if (titleElement != null && artistElement != null && imageElement != null) {
          final title = titleElement.text.trim();
          final artist = artistElement.text.trim();
          final imageUrl = imageElement.attributes['data-lazy-src'] ?? '';

          fetchedNews.add({
            'title': title,
            'description': artist,
            'imageUrl': imageUrl,
          });
        }
      }

      setState(() {
        musicNews = fetchedNews;
      });
    } else {
      throw Exception('Failed to load music news');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Hot 100'),
      ),
      body: musicNews.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: musicNews.length,
        itemBuilder: (context, index) {
          final news = musicNews[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (news['imageUrl']!.isNotEmpty)
                    Image.network(
                      news['imageUrl']!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news['title']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(news['description']!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

