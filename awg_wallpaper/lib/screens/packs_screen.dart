import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/pack_provider.dart';
import '../widgets/pack_card.dart';
import 'pack_detail_screen.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackProvider>().fetchPacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<PackProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),

                // Free Packs Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Free Collections', true),
                ),
                SliverToBoxAdapter(
                  child: _buildPacksList(context, provider.freePacks),
                ),

                // Pro Packs Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Pro Collections', false),
                ),
                SliverToBoxAdapter(
                  child: _buildPacksList(context, provider.proPacks),
                ),

                // All Packs Grid
                SliverToBoxAdapter(
                  child: _buildAllPacksHeader(),
                ),
                _buildAllPacksGrid(context, provider.packs),

                // Bottom padding for nav bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallpaper Packs',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Curated collections for you',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isFree) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFree
                    ? [
                        AppTheme.success.withOpacity(0.2),
                        AppTheme.success.withOpacity(0.1)
                      ]
                    : [
                        AppTheme.gold.withOpacity(0.2),
                        AppTheme.gold.withOpacity(0.1)
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFree
                  ? Icons.folder_special_rounded
                  : Icons.workspace_premium_rounded,
              color: isFree ? AppTheme.success : AppTheme.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacksList(BuildContext context, List packs) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final pack = packs[index];
          return PackCard(
            pack: pack,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PackDetailScreen(packId: pack.id, packName: pack.name),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAllPacksHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          Icon(
            Icons.apps_rounded,
            color: AppTheme.primary,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'All Packs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPacksGrid(BuildContext context, List packs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final pack = packs[index];
            return PackCard(
              pack: pack,
              isLarge: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PackDetailScreen(packId: pack.id, packName: pack.name),
                  ),
                );
              },
            );
          },
          childCount: packs.length,
        ),
      ),
    );
  }
}
