import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../providers/subscription_provider.dart';
import 'wallpaper_detail_screen.dart';

import '../utils/ad_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: SafeArea(
        child: Consumer2<SearchProvider, WallpaperProvider>(
          builder: (context, searchProvider, wallpaperProvider, child) {
            return Column(
              children: [
                // Search bar
                _buildSearchBar(context, searchProvider, wallpaperProvider, isDark),

                // Content
                Expanded(
                  child: searchProvider.query.isEmpty
                      ? _buildSearchHistory(searchProvider, wallpaperProvider, isDark)
                      : _buildSearchResults(searchProvider, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    SearchProvider searchProvider,
    WallpaperProvider wallpaperProvider,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppTheme.getSurfaceVariant(isDark)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.getTextPrimary(isDark),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.getSurfaceVariant(isDark),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(
                  color: AppTheme.getTextPrimary(isDark),
                  fontSize: 16,
                ),
                cursorColor: AppTheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search wallpapers...',
                  hintStyle: TextStyle(color: AppTheme.getTextMuted(isDark)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.getTextSecondary(isDark),
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            searchProvider.clearSearch();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: AppTheme.getTextSecondary(isDark),
                            size: 20,
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  searchProvider.setQuery(value);
                  searchProvider.search(wallpaperProvider.wallpapers);
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    searchProvider.addToHistory(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory(
    SearchProvider searchProvider,
    WallpaperProvider wallpaperProvider,
    bool isDark,
  ) {
    return CustomScrollView(
      slivers: [
        if (searchProvider.searchHistory.isNotEmpty) ...[
          // History header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                  ),
                  GestureDetector(
                    onTap: searchProvider.clearHistory,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: searchProvider.searchHistory.map((query) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = query;
                      searchProvider.setQuery(query);
                      searchProvider.search(wallpaperProvider.wallpapers);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(isDark),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppTheme.getSurfaceVariant(isDark)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: AppTheme.getTextSecondary(isDark),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            query,
                            style: TextStyle(
                              color: AppTheme.getTextPrimary(isDark),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                searchProvider.removeFromHistory(query),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppTheme.getTextSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],

        // Suggestions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      wallpaperProvider.categories.skip(1).take(6).map((cat) {
                    return GestureDetector(
                      onTap: () {
                        _controller.text = cat.name;
                        searchProvider.setQuery(cat.name);
                        searchProvider.search(wallpaperProvider.wallpapers);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: AppTheme.getTextPrimary(isDark),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(SearchProvider searchProvider, bool isDark) {
    if (searchProvider.results.isEmpty) {
      return _buildNoResults(isDark);
    }

    return CustomScrollView(
      slivers: [
        // Results count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              '${searchProvider.results.length} results for "${searchProvider.query}"',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondary(isDark),
              ),
            ),
          ),
        ),

        // Results grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemBuilder: (context, index) {
              final results = searchProvider.results;
              final wallpaper = results[index];
              final height =
                  index % 3 == 0 ? 280.0 : (index % 3 == 1 ? 220.0 : 250.0);

              return WallpaperCard(
                wallpaper: wallpaper,
                height: height,
                onTap: () {
                  final isPro = context.read<SubscriptionProvider>().isPro;
                  if (!isPro) {
                    AdHelper.showInterstitialAd(
                      onAdClosed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WallpaperDetailScreen(
                              wallpapers: results,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperDetailScreen(
                          wallpapers: results,
                          initialIndex: index,
                        ),
                      ),
                    );
                  }
                },
              );
            },
            childCount: searchProvider.results.length,
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

