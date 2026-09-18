import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/page_header.dart';

class NotificationTemplateModel {
  final int id;
  final String name;
  final String title;
  final String message;
  final String? imageUrl;
  final String category;
  final bool isPremade;

  NotificationTemplateModel({
    required this.id,
    required this.name,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.category,
    required this.isPremade,
  });

  factory NotificationTemplateModel.fromJson(Map<String, dynamic> json) {
    return NotificationTemplateModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      category: json['category']?.toString() ?? 'general',
      isPremade: json['isPremade'] == true || json['is_premade'] == true,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sending = false;
  bool _uploadingImage = false;
  bool _loadingTemplates = false;
  List<NotificationTemplateModel> _templates = [];

  final _bTitleCtrl = TextEditingController();
  final _bMessageCtrl = TextEditingController();
  final _bImageCtrl = TextEditingController();

  final _uIdCtrl = TextEditingController();
  final _uTitleCtrl = TextEditingController();
  final _uMessageCtrl = TextEditingController();
  final _uImageCtrl = TextEditingController();

  final _tTokenCtrl = TextEditingController();
  final _tTitleCtrl = TextEditingController();
  final _tMessageCtrl = TextEditingController();
  final _tImageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _bTitleCtrl,
      _bMessageCtrl,
      _bImageCtrl,
      _uIdCtrl,
      _uTitleCtrl,
      _uMessageCtrl,
      _uImageCtrl,
      _tTokenCtrl,
      _tTitleCtrl,
      _tMessageCtrl,
      _tImageCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _loadingTemplates = true);
    try {
      final res = await ApiService.get('/notifications/templates');
      if (res != null && res['templates'] is List) {
        final list = (res['templates'] as List)
            .map((item) => NotificationTemplateModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _templates = list);
      }
    } catch (e) {
      debugPrint('Failed to load templates: $e');
    } finally {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  TextEditingController get _currentTitleCtrl {
    switch (_tabController.index) {
      case 1:
        return _uTitleCtrl;
      case 2:
        return _tTitleCtrl;
      default:
        return _bTitleCtrl;
    }
  }

  TextEditingController get _currentMessageCtrl {
    switch (_tabController.index) {
      case 1:
        return _uMessageCtrl;
      case 2:
        return _tMessageCtrl;
      default:
        return _bMessageCtrl;
    }
  }

  TextEditingController get _currentImageCtrl {
    switch (_tabController.index) {
      case 1:
        return _uImageCtrl;
      case 2:
        return _tImageCtrl;
      default:
        return _bImageCtrl;
    }
  }

  void _applyTemplate(NotificationTemplateModel tpl) {
    setState(() {
      _currentTitleCtrl.text = tpl.title;
      _currentMessageCtrl.text = tpl.message;
      _currentImageCtrl.text = tpl.imageUrl ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "${tpl.name}" applied!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _uploadingImage = true);

      final bytes = await picked.readAsBytes();
      final multipart = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: picked.name,
      );

      final res = await ApiService.postMultipart(
        '/notifications/upload-image',
        {},
        [multipart],
      );

      if (res != null && res['url'] != null) {
        setState(() {
          controller.text = res['url'].toString();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thumbnail uploaded successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _openSaveTemplateDialog() async {
    final nameCtrl = TextEditingController(
      text: _currentTitleCtrl.text.isNotEmpty
          ? '${_currentTitleCtrl.text.characters.take(20)} Template'
          : 'New Template',
    );
    final titleCtrl = TextEditingController(text: _currentTitleCtrl.text);
    final messageCtrl = TextEditingController(text: _currentMessageCtrl.text);
    final imageCtrl = TextEditingController(text: _currentImageCtrl.text);
    String category = 'general';
    bool savingTpl = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (bottomSheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Save as Template',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'e.g. Weekend AMOLED Drop',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'drop', child: Text('New Drop')),
                    DropdownMenuItem(value: 'trending', child: Text('Trending')),
                    DropdownMenuItem(value: 'promo', child: Text('Promotion / Pro')),
                    DropdownMenuItem(value: 'featured', child: Text('Featured / AMOLED')),
                    DropdownMenuItem(value: 'community', child: Text('Community')),
                    DropdownMenuItem(value: 'update', child: Text('App Update')),
                    DropdownMenuItem(value: 'general', child: Text('General')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Notification Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notification Message'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Thumbnail URL (Optional)',
                          hintText: 'https://…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.upload_file_rounded),
                      tooltip: 'Upload Image',
                      onPressed: () async {
                        await _pickAndUploadImage(imageCtrl);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: savingTpl
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                titleCtrl.text.trim().isEmpty ||
                                messageCtrl.text.trim().isEmpty) {
                              if (bottomSheetContext.mounted) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Name, title, and message are required.'),
                                  ),
                                );
                              }
                              return;
                            }

                            setSheetState(() => savingTpl = true);
                            try {
                              await ApiService.post('/notifications/templates', {
                                'name': nameCtrl.text.trim(),
                                'title': titleCtrl.text.trim(),
                                'message': messageCtrl.text.trim(),
                                if (imageCtrl.text.trim().isNotEmpty)
                                  'imageUrl': imageCtrl.text.trim(),
                                'category': category,
                              });
                              if (bottomSheetContext.mounted) Navigator.pop(bottomSheetContext);
                              _loadTemplates();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Template saved successfully!'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (bottomSheetContext.mounted) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            } finally {
                              setSheetState(() => savingTpl = false);
                            }
                          },
                    child: savingTpl
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Template'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplatesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (bottomSheetContext, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Notification Templates (${_templates.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Create New Template',
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _openSaveTemplateDialog();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loadingTemplates
                    ? const Center(child: CircularProgressIndicator())
                    : _templates.isEmpty
                        ? const Center(
                            child: Text(
                              'No templates found.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _templates.length,
                            separatorBuilder: (context, sepIndex) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final tpl = _templates[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: AppTheme.surfaceVariant,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tpl.isPremade
                                                  ? AppTheme.primary.withAlpha(30)
                                                  : Colors.blue.withAlpha(30),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tpl.isPremade ? 'PREMADE' : 'CUSTOM',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: tpl.isPremade
                                                    ? AppTheme.primary
                                                    : Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              tpl.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!tpl.isPremade)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () async {
                                                try {
                                                  await ApiService.delete(
                                                    '/notifications/templates/${tpl.id}',
                                                  );
                                                  setSheetState(() {
                                                    _templates.removeWhere((t) => t.id == tpl.id);
                                                  });
                                                  setState(() {});
                                                } catch (e) {
                                                  if (bottomSheetContext.mounted) {
                                                    ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                                      SnackBar(content: Text('Delete failed: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        tpl.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tpl.message,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (tpl.imageUrl != null && tpl.imageUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: tpl.imageUrl!,
                                            height: 80,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (c, url) => Container(
                                              height: 80,
                                              color: AppTheme.surfaceVariant,
                                            ),
                                            errorWidget: (c, url, err) => const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FilledButton.tonalIcon(
                                          icon: const Icon(Icons.check_rounded, size: 16),
                                          label: const Text('Use Template'),
                                          style: FilledButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(bottomSheetContext);
                                            _applyTemplate(tpl);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    if (_bTitleCtrl.text.isEmpty || _bMessageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.post('/notifications/send-to-all', {
        'title': _bTitleCtrl.text,
        'message': _bMessageCtrl.text,
        if (_bImageCtrl.text.isNotEmpty) 'imageUrl': _bImageCtrl.text,
      });
      _bTitleCtrl.clear();
      _bMessageCtrl.clear();
      _bImageCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendToUser() async {
    if (_uIdCtrl.text.isEmpty ||
        _uTitleCtrl.text.isEmpty ||
        _uMessageCtrl.text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiService.post('/notifications/send-to-user', {
        'userId': _uIdCtrl.text,
        'title': _uTitleCtrl.text,
        'message': _uMessageCtrl.text,
        if (_uImageCtrl.text.isNotEmpty) 'imageUrl': _uImageCtrl.text,
      });
      _uIdCtrl.clear();
      _uTitleCtrl.clear();
      _uMessageCtrl.clear();
      _uImageCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendTest() async {
    if (_tTokenCtrl.text.isEmpty ||
        _tTitleCtrl.text.isEmpty ||
        _tMessageCtrl.text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiService.post('/notifications/test', {
        'token': _tTokenCtrl.text,
        'title': _tTitleCtrl.text,
        'message': _tMessageCtrl.text,
        if (_tImageCtrl.text.isNotEmpty) 'imageUrl': _tImageCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test sent!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(
            title: 'Notifications',
            subtitle: 'Send rich push notifications and manage templates',
            trailing: ActionChip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primary),
              label: Text(
                _templates.isEmpty ? 'Templates' : 'Templates (${_templates.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              onPressed: _showTemplatesSheet,
            ),
          ),
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Broadcast'),
                Tab(text: 'To User'),
                Tab(text: 'Test'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTab(
                  title: 'Send to All Users',
                  fields: [
                    _FieldDef(_bTitleCtrl, 'Title', hint: 'e.g. Fresh 4K Drops! ✨'),
                    _FieldDef(_bMessageCtrl, 'Message', maxLines: 3, hint: 'e.g. Explore new wallpapers.'),
                  ],
                  imageCtrl: _bImageCtrl,
                  buttonLabel: 'Send Broadcast',
                  onSend: _sendBroadcast,
                ),
                _buildTab(
                  title: 'Send to Specific User',
                  fields: [
                    _FieldDef(_uIdCtrl, 'User ID', hint: 'e.g. 104'),
                    _FieldDef(_uTitleCtrl, 'Title'),
                    _FieldDef(_uMessageCtrl, 'Message', maxLines: 3),
                  ],
                  imageCtrl: _uImageCtrl,
                  buttonLabel: 'Send Notification',
                  onSend: _sendToUser,
                ),
                _buildTab(
                  title: 'Test Notification',
                  fields: [
                    _FieldDef(_tTokenCtrl, 'Device Token', maxLines: 2, hint: 'Paste device FCM token here'),
                    _FieldDef(_tTitleCtrl, 'Title'),
                    _FieldDef(_tMessageCtrl, 'Message', maxLines: 3),
                  ],
                  imageCtrl: _tImageCtrl,
                  buttonLabel: 'Send Test',
                  onSend: _sendTest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required List<_FieldDef> fields,
    required TextEditingController imageCtrl,
    required String buttonLabel,
    required VoidCallback onSend,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Templates Chip Bar
          if (_templates.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Quick Templates',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showTemplatesSheet,
                        child: const Text(
                          'View All →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _templates.take(5).map((tpl) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(
                              tpl.name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: AppTheme.surfaceVariant.withAlpha(128),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () => _applyTemplate(tpl),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...fields.expand(
                    (f) => [
                      TextField(
                        controller: f.controller,
                        decoration: InputDecoration(
                          labelText: f.label,
                          hintText: f.hint,
                        ),
                        maxLines: f.maxLines,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                  // Thumbnail image input with upload button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Thumbnail Image URL (optional)',
                            hintText: 'https://… or pick from gallery',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: _uploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library_rounded),
                        tooltip: 'Upload image from gallery',
                        onPressed: _uploadingImage ? null : () => _pickAndUploadImage(imageCtrl),
                      ),
                    ],
                  ),

                  // Thumbnail preview
                  if (imageCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.surfaceVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageCtrl.text,
                            fit: BoxFit.cover,
                            placeholder: (c, url) => Container(
                              color: AppTheme.surfaceVariant,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (c, url, err) => Container(
                              color: AppTheme.surfaceVariant,
                              child: const Center(
                                child: Text('Failed to preview image', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black.withAlpha(150),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                onPressed: () => setState(() => imageCtrl.clear()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _sending ? null : onSend,
                            icon: _sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(buttonLabel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        icon: const Icon(Icons.bookmark_add_outlined),
                        tooltip: 'Save as Template',
                        onPressed: _openSaveTemplateDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldDef {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? hint;
  const _FieldDef(this.controller, this.label, {this.maxLines = 1, this.hint});
}
