import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/wallpaper_card.dart';
import 'wallpaper_detail_screen.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer2<SearchProvider, WallpaperProvider>(
          builder: (context, searchProvider, wallpaperProvider, child) {
            return Column(
              children: [
                // Search bar
                _buildSearchBar(context, searchProvider, wallpaperProvider),
                
                // Content
                Expanded(
                  child: searchProvider.query.isEmpty
                      ? _buildSearchHistory(searchProvider, wallpaperProvider)
                      : _buildSearchResults(searchProvider),
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
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppTheme.surfaceVariant),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus 
                      ? AppTheme.primary
                      : AppTheme.surfaceVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
                cursorColor: AppTheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search wallpapers...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            searchProvider.clearSearch();
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
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
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
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
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppTheme.surfaceVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            query,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => searchProvider.removeFromHistory(query),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppTheme.textSecondary,
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
                const Text(
                  'Popular Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: wallpaperProvider.categories.skip(1).take(6).map((cat) {
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
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
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
  
  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.results.isEmpty) {
      return _buildNoResults();
    }
    
    return CustomScrollView(
      slivers: [
        // Results count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              '${searchProvider.results.length} results for "${searchProvider.query}"',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
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
              final height = index % 3 == 0 ? 280.0 : (index % 3 == 1 ? 220.0 : 250.0);
              
              return WallpaperCard(
                wallpaper: wallpaper,
                height: height,
                onTap: () {
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
  
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
