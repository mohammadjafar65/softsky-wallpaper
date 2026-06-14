import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  List _packs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/packs');
      final raw = data['packs'] ?? data;
      if (!mounted) return;
      setState(() => _packs = raw is List ? raw : []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Pack',
      message: 'This pack will be removed permanently.',
    );
    if (!confirmed) return;
    try {
      await ApiService.delete('/packs/$id');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(title: 'Packs', subtitle: '${_packs.length} packs'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _packs.isEmpty
                    ? const EmptyState(
                        icon: Icons.collections_rounded,
                        title: 'No packs yet',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _packs.length,
                          itemBuilder: (context, i) {
                            final pack = _packs[i] as Map<String, dynamic>;
                            final thumbUrl = pack['thumbnailUrl'] as String?;
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (thumbUrl != null)
                                    CachedNetworkImage(
                                      imageUrl: thumbUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, url, err) => Container(
                                        color: AppTheme.surfaceVariant,
                                        child: const Icon(
                                          Icons.collections_outlined,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      color: AppTheme.surfaceVariant,
                                      child: const Icon(
                                        Icons.collections_outlined,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 20, 10, 10),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black87,
                                            Colors.transparent
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        pack['name'] as String? ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _delete(pack['id'].toString()),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
