import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:awg_wallpaper/models/wallpaper.dart';
import 'package:awg_wallpaper/providers/search_provider.dart';
import 'package:awg_wallpaper/providers/wallpaper_provider.dart';
import 'package:awg_wallpaper/services/api_service.dart';

Map<String, dynamic> wallpaper(String id, {String category = '1'}) => {
      'id': id,
      'title': 'Wallpaper $id',
      'imageUrl': 'https://example.com/$id.jpg',
      'thumbnailUrl': 'https://example.com/$id-thumb.jpg',
      'category': category,
      'isPro': false,
      'isWide': false,
      'downloads': 0,
    };

http.Response page(List<Map<String, dynamic>> items,
        {int number = 1, int pages = 3}) =>
    http.Response(
        jsonEncode({
          'wallpapers': items,
          'pagination': {
            'page': number,
            'limit': 20,
            'total': 60,
            'pages': pages,
          }
        }),
        200);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('softsky-tests-');
    Hive.init(directory.path);
    await Hive.openBox('settings');
    await Hive.openBox('cache');
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('missing thumbnails fall back to the original image', () {
    final data = wallpaper('1')..['thumbnailUrl'] = '';
    expect(Wallpaper.fromJson(data).thumbnailUrl, 'https://example.com/1.jpg');
  });

  test('a slow packs request does not hold the free wallpaper feed', () async {
    final packs = Completer<http.Response>();
    await http.runWithClient(() async {
      final provider = WallpaperProvider();
      await settle();
      expect(provider.wallpapers.map((w) => w.id), ['1']);
      expect(provider.isLoading, false);
      packs.complete(http.Response('{"packs":[]}', 200));
      await settle();
      provider.dispose();
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/packs')) return packs.future;
              if (request.url.path.endsWith('/categories')) {
                return http.Response('{"categories":[]}', 200);
              }
              return page([wallpaper('1')]);
            }));
  });

  test('failed refresh preserves cached wallpapers and exposes the error',
      () async {
    await Hive.box('cache')
        .put('wallpapers', jsonEncode([wallpaper('cached')]));
    await http.runWithClient(() async {
      final provider = WallpaperProvider();
      await settle();
      expect(provider.wallpapers.map((w) => w.id), ['cached']);
      expect(provider.error, isNotNull);
      final cached =
          jsonDecode(Hive.box('cache').get('wallpapers') as String) as List;
      expect(cached.single['id'], 'cached');
      provider.dispose();
    }, () => MockClient((_) async => http.Response('{}', 500)));
  });

  test(
      'category requests use consistent page sizes and returning to All reloads page one',
      () async {
    final queries = <Map<String, String>>[];
    await http.runWithClient(() async {
      final provider = WallpaperProvider();
      await settle();
      provider.setSelectedCategory('nature');
      await settle();
      expect(provider.wallpapers.map((w) => w.id), ['nature-1']);
      expect(provider.getWallpaperById('nature-1')?.id, 'nature-1');
      await provider.loadMoreWallpapers();
      expect(provider.wallpapers.map((w) => w.id), ['nature-1', 'nature-2']);
      provider.setSelectedCategory('all');
      await settle();
      expect(provider.wallpapers.map((w) => w.id), ['all-1']);
      expect(
          queries
              .where((q) => q['category'] == 'nature')
              .map((q) => q['limit']),
          ['20', '20']);
      provider.dispose();
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/categories')) {
                return http.Response(
                    '{"categories":[{"id":1,"name":"Nature","slug":"nature","icon":"N"}]}',
                    200);
              }
              if (request.url.path.endsWith('/packs')) {
                return http.Response('{"packs":[]}', 200);
              }
              final query = request.url.queryParameters;
              queries.add(query);
              final number = int.parse(query['page']!);
              return page([wallpaper('${query['category'] ?? 'all'}-$number')],
                  number: number);
            }));
  });

  test('search ignores responses for an older query', () async {
    final old = Completer<http.Response>();
    await http.runWithClient(() async {
      final provider = SearchProvider();
      final first = provider.searchWithQuery('old');
      await settle();
      await provider.searchWithQuery('new');
      old.complete(page([wallpaper('old')]));
      await first;
      expect(provider.results.map((w) => w.id), ['new']);
      provider.dispose();
    },
        () => MockClient((request) async =>
            request.url.queryParameters['q'] == 'old'
                ? await old.future
                : page([wallpaper('new')])));
  });

  test('clearing search invalidates an in-flight response', () async {
    final response = Completer<http.Response>();
    await http.runWithClient(() async {
      final provider = SearchProvider();
      final search = provider.searchWithQuery('old');
      await settle();
      provider.clearSearch();
      response.complete(page([wallpaper('old')]));
      await search;
      expect(provider.results, isEmpty);
      provider.dispose();
    }, () => MockClient((_) => response.future));
  });

  test('typing uses one debounced request instead of requesting each keystroke',
      () async {
    final queries = <String>[];
    await http.runWithClient(() async {
      final provider = SearchProvider();
      provider.setQuery('n');
      provider.setQuery('na');
      provider.setQuery('nature');
      await Future<void>.delayed(const Duration(milliseconds: 550));
      expect(queries, ['nature']);
      provider.dispose();
    },
        () => MockClient((request) async {
              queries.add(request.url.queryParameters['q']!);
              return page([wallpaper('nature')]);
            }));
  });

  test('a failed like toggle is not retried and accidentally toggled twice',
      () async {
    var attempts = 0;
    await http.runWithClient(() async {
      await expectLater(ApiService().toggleLike(1), throwsException);
      expect(attempts, 1);
    },
        () => MockClient((_) async {
              attempts++;
              return attempts == 1
                  ? http.Response('{"error":"Unavailable"}', 503)
                  : http.Response('{"liked":true}', 200);
            }));
  });

  test('switching categories ignores a slower previous response', () async {
    final old = Completer<http.Response>();
    await http.runWithClient(() async {
      final provider = WallpaperProvider();
      await settle();
      provider.setSelectedCategory('old');
      await settle();
      provider.setSelectedCategory('new');
      await settle();
      old.complete(page([wallpaper('old')]));
      await settle();
      expect(provider.wallpapers.map((w) => w.id), ['new']);
      expect(provider.isLoading, false);
      provider.dispose();
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/packs')) {
                return http.Response('{"packs":[]}', 200);
              }
              if (request.url.path.endsWith('/categories')) {
                return http.Response('{"categories":[]}', 200);
              }
              if (request.url.queryParameters['category'] == 'old') {
                return old.future;
              }
              return page([
                wallpaper(request.url.queryParameters['category'] ?? 'all')
              ]);
            }));
  });
}
