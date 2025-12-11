import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/pack_provider.dart';
import '../models/wallpaper_pack.dart';
import '../widgets/wallpaper_card.dart';
import 'wallpaper_detail_screen.dart';

class PackDetailScreen extends StatefulWidget {
  final String packId;
  final String packName;

  const PackDetailScreen(
      {super.key, required this.packId, required this.packName});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  WallpaperPack? _pack;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final pack =
        await context.read<PackProvider>().getPackDetails(widget.packId);
    if (mounted) {
      setState(() {
        _pack = pack;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pack == null
              ? Center(child: Text("Pack not found"))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(_pack!.name),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: _pack!.coverImage,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _pack!.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final wallpaper = _pack!.wallpapers[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WallpaperDetailScreen(
                                      wallpapers: _pack!.wallpapers,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: wallpaper.id,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: wallpaper.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey[800]),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _pack!.wallpapers.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
    );
  }
}
