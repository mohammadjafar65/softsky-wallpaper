import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  List _wallpapers = [];
  List _categories = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  final int _limit = 20;
  String _search = '';
  String _catFilter = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _wallpapers = [];
    }
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'page': '$_page',
        'limit': '$_limit',
        if (_search.isNotEmpty) 'search': _search,
        if (_catFilter.isNotEmpty) 'category': _catFilter,
      };
      final results = await Future.wait([
        ApiService.get('/wallpapers', params: params),
        if (_categories.isEmpty) ApiService.get('/categories'),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      if (_categories.isEmpty && results.length > 1) {
        _categories =
            (results[1] as Map<String, dynamic>)['categories'] as List? ?? [];
      }
      setState(() {
        _wallpapers = data['wallpapers'] as List? ?? [];
        _total =
            (data['pagination'] as Map<String, dynamic>?)?['total'] as int? ??
            0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Wallpaper',
      message: 'This cannot be undone.',
    );
    if (!confirmed) return;
    try {
      await ApiService.delete('/wallpapers/$id');
      _load(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showUploadSheet() async {
    if (_categories.isEmpty) {
      await _loadCategories();
    }
    if (!mounted) return;

    final titleCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    List<PlatformFile> selectedFiles = [];
    String? selectedCategoryId = _categories.isNotEmpty
        ? _categories.first['id']?.toString()
        : null;
    bool isPro = false;
    bool isWide = false;
    bool saving = false;
    int uploadedCount = 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickImage() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: true,
                withData: true,
              );
              if (result != null && result.files.isNotEmpty) {
                setSheetState(() => selectedFiles = result.files);
              }
            }

            void autoFillMetadata() {
              if (selectedFiles.isEmpty) return;
              final categoryName = _categoryName(selectedCategoryId);
              setSheetState(() {
                titleCtrl.text = _generatedTitle(
                  selectedFiles.first,
                  categoryName: categoryName,
                );
                tagsCtrl.text = _generatedTags(
                  selectedFiles.first,
                  categoryName: categoryName,
                );
              });
            }

            Future<void> upload() async {
              if (saving) return;
              if (selectedCategoryId == null || selectedFiles.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Category and at least one image are required.',
                    ),
                  ),
                );
                return;
              }

              for (final file in selectedFiles) {
                if (_imageContentType(file.name) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${file.name} is not a supported image.'),
                    ),
                  );
                  return;
                }
              }

              setSheetState(() {
                saving = true;
                uploadedCount = 0;
              });
              var uploadCompleted = false;
              try {
                for (var index = 0; index < selectedFiles.length; index += 1) {
                  final file = selectedFiles[index];
                  final categoryName = _categoryName(selectedCategoryId);
                  final manualTitle = titleCtrl.text.trim();
                  final title = manualTitle.isEmpty
                      ? _generatedTitle(file, categoryName: categoryName)
                      : selectedFiles.length == 1
                      ? manualTitle
                      : '$manualTitle ${index + 1}';
                  final manualTags = tagsCtrl.text.trim();
                  final tags = manualTags.isEmpty
                      ? _generatedTags(file, categoryName: categoryName)
                      : manualTags;

                  await ApiService.postMultipart(
                    '/wallpapers',
                    {
                      'title': title,
                      'category': selectedCategoryId!,
                      'tags': tags,
                      'isWide': isWide.toString(),
                      'isPro': isPro.toString(),
                    },
                    [await _multipartImageFile(file)],
                  );

                  setSheetState(() => uploadedCount = index + 1);
                }

                if (!mounted || !context.mounted || !sheetContext.mounted) {
                  return;
                }
                uploadCompleted = true;
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      selectedFiles.length == 1
                          ? 'Wallpaper uploaded.'
                          : '${selectedFiles.length} wallpapers uploaded.',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
                _load(reset: true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              } finally {
                if (!uploadCompleted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Upload Wallpaper',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saving ? null : pickImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(
                        selectedFiles.isEmpty
                            ? 'Choose images'
                            : '${selectedFiles.length} image${selectedFiles.length == 1 ? '' : 's'} selected',
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedFiles
                            .map(
                              (file) => Chip(
                                label: Text(
                                  file.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onDeleted: saving
                                    ? null
                                    : () => setSheetState(
                                        () => selectedFiles = selectedFiles
                                            .where((item) => item != file)
                                            .toList(),
                                      ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: selectedFiles.length > 1
                            ? 'Base title'
                            : 'Title',
                        hintText: 'Auto-generated if empty',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem<String>(
                              value: cat['id']?.toString(),
                              child: Text(
                                cat['name']?.toString() ?? 'Untitled',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) =>
                                setSheetState(() => selectedCategoryId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Auto-generated if empty',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: saving || selectedFiles.isEmpty
                            ? null
                            : autoFillMetadata,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('Auto-generate title and tags'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isPro,
                      onChanged: saving
                          ? null
                          : (v) => setSheetState(() => isPro = v),
                      title: const Text('Pro wallpaper'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: isWide,
                      onChanged: saving
                          ? null
                          : (v) => setSheetState(() => isWide = v),
                      title: const Text('Wide wallpaper'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    if (saving && selectedFiles.length > 1) ...[
                      LinearProgressIndicator(
                        value: selectedFiles.isEmpty
                            ? null
                            : uploadedCount / selectedFiles.length,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded $uploadedCount of ${selectedFiles.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : upload,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          saving
                              ? 'Uploading...'
                              : selectedFiles.length > 1
                              ? 'Upload ${selectedFiles.length} wallpapers'
                              : 'Upload',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    tagsCtrl.dispose();
  }

  Future<void> _loadCategories() async {
    final data = await ApiService.get('/categories');
    if (!mounted) return;
    setState(() {
      _categories = (data as Map<String, dynamic>)['categories'] as List? ?? [];
    });
  }

  MediaType? _imageContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return null;
    }
  }

  String _categoryName(String? categoryId) {
    for (final category in _categories) {
      if (category is Map && category['id']?.toString() == categoryId) {
        return category['name']?.toString() ?? 'Wallpaper';
      }
    }
    return 'Wallpaper';
  }

  String _generatedTitle(PlatformFile file, {required String categoryName}) {
    final words = _fileNameWords(file.name);
    if (words.isEmpty) {
      return categoryName;
    }

    return words.map(_titleCase).join(' ');
  }

  String _generatedTags(PlatformFile file, {required String categoryName}) {
    final tags = <String>{
      ..._fileNameWords(categoryName).map((word) => word.toLowerCase()),
      ..._fileNameWords(file.name).map((word) => word.toLowerCase()),
    };
    tags.removeWhere((tag) => tag.length < 2 || int.tryParse(tag) != null);
    return tags.take(8).join(', ');
  }

  List<String> _fileNameWords(String value) {
    final baseName = value.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return baseName
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Future<http.MultipartFile> _multipartImageFile(PlatformFile file) async {
    final contentType = _imageContentType(file.name);
    if (contentType == null) {
      throw ApiException('Please choose JPG, PNG, WebP, or GIF images.');
    }

    if (file.path != null) {
      return http.MultipartFile.fromPath(
        'image',
        file.path!,
        contentType: contentType,
      );
    }

    return http.MultipartFile.fromBytes(
      'image',
      file.bytes ?? (throw ApiException('Could not read ${file.name}.')),
      filename: file.name,
      contentType: contentType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showUploadSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(
          Icons.add_photo_alternate_rounded,
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          PageHeader(title: 'Wallpapers', subtitle: '$_total total'),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _wallpapers.isEmpty
                ? const EmptyState(
                    icon: Icons.wallpaper_rounded,
                    title: 'No wallpapers found',
                    subtitle: 'Try a different search or filter.',
                  )
                : _buildGrid(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search wallpapers...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _search = '';
                            _load(reset: true);
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                ),
                onSubmitted: (v) {
                  _search = v;
                  _load(reset: true);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _catFilter.isEmpty ? null : _catFilter,
              hint: const Text('Category', style: TextStyle(fontSize: 13)),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              borderRadius: BorderRadius.circular(8),
              onChanged: (v) {
                _catFilter = v ?? '';
                _load(reset: true);
              },
              items: [
                const DropdownMenuItem(value: '', child: Text('All')),
                ..._categories.map(
                  (c) => DropdownMenuItem(
                    value: c['slug']?.toString() ?? '',
                    child: Text(c['name']?.toString() ?? 'Untitled'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _wallpapers.length,
      itemBuilder: (context, i) {
        final w = _wallpapers[i] as Map<String, dynamic>;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl:
                    w['thumbnailUrl'] as String? ??
                    w['imageUrl'] as String? ??
                    '',
                fit: BoxFit.cover,
                errorWidget: (_, url, err) => Container(
                  color: AppTheme.surfaceVariant,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          w['title'] as String? ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (w['isPro'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _delete(w['id'].toString()),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _limit).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    _page--;
                    _load();
                  }
                : null,
          ),
          Text(
            '$_page / $totalPages',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    _page++;
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
