import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List _categories = [];
  bool _loading = true;
  bool _includeInactive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '/categories',
        params: {'includeInactive': _includeInactive.toString()},
      );
      if (!mounted) return;
      setState(() => _categories = data['categories'] as List? ?? []);
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
      title: 'Delete Category',
      message: 'All wallpapers in this category may be affected.',
    );
    if (!confirmed) return;
    try {
      await ApiService.delete('/categories/$id');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showCategoryDialog([Map<String, dynamic>? category]) async {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?['name']?.toString() ?? '');
    final iconCtrl = TextEditingController(text: category?['icon']?.toString() ?? '');
    final descCtrl = TextEditingController(
      text: category?['description']?.toString() ?? '',
    );
    bool isActive = category?['isActive'] != false;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (saving) return;
            if (nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category name is required.')),
              );
              return;
            }

            setDialogState(() => saving = true);
            try {
              final body = {
                'name': nameCtrl.text.trim(),
                'icon': iconCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                if (isEditing) 'isActive': isActive,
              };
              if (isEditing) {
                await ApiService.put('/categories/${category['id']}', body);
              } else {
                await ApiService.post('/categories', body);
              }

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Category updated.' : 'Category created.'),
                  backgroundColor: AppTheme.success,
                ),
              );
              _load();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            } finally {
              setDialogState(() => saving = false);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEditing ? 'Edit Category' : 'New Category',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iconCtrl,
                    decoration: const InputDecoration(labelText: 'Icon'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => isActive = value),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              OutlinedButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving...' : isEditing ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    iconCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _refetchPinterest(Map<String, dynamic> category) async {
    try {
      await ApiService.post('/categories/${category['id']}/refetch-pinterest', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pinterest category refetched.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          PageHeader(
            title: 'Categories',
            subtitle: '${_categories.length} categories',
            trailing: IconButton(
              tooltip: _includeInactive ? 'Hide inactive' : 'Show inactive',
              icon: Icon(
                _includeInactive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() => _includeInactive = !_includeInactive);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? const EmptyState(
                        icon: Icons.category_rounded,
                        title: 'No categories yet',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _categories.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final cat = _categories[i] as Map<String, dynamic>;
                            final desc = cat['description'] as String? ?? '';
                            final sourceUrl = cat['sourceUrl']?.toString() ?? '';
                            final isActive = cat['isActive'] != false;
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isActive
                                        ? Icons.category_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.info,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  cat['name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: desc.isNotEmpty
                                    ? Text(
                                        desc,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        '/${cat['slug']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isActive
                                              ? AppTheme.textSecondary
                                              : AppTheme.error,
                                        ),
                                      ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${cat['wallpaperCount'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.wallpaper_outlined,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showCategoryDialog(cat);
                                        } else if (value == 'refetch') {
                                          _refetchPinterest(cat);
                                        } else if (value == 'delete') {
                                          _delete(cat['id'].toString());
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        if (sourceUrl.contains('pinterest.com'))
                                          const PopupMenuItem(
                                            value: 'refetch',
                                            child: Text('Refetch Pinterest'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
