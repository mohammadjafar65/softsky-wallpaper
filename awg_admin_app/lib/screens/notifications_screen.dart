import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/page_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sending = false;

  final _bTitleCtrl = TextEditingController();
  final _bMessageCtrl = TextEditingController();
  final _bImageCtrl = TextEditingController();

  final _uIdCtrl = TextEditingController();
  final _uTitleCtrl = TextEditingController();
  final _uMessageCtrl = TextEditingController();

  final _tTokenCtrl = TextEditingController();
  final _tTitleCtrl = TextEditingController();
  final _tMessageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _tTokenCtrl,
      _tTitleCtrl,
      _tMessageCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
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
      });
      _uIdCtrl.clear();
      _uTitleCtrl.clear();
      _uMessageCtrl.clear();
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
          const PageHeader(
            title: 'Notifications',
            subtitle: 'Send push notifications to users',
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
                    _FieldDef(_bTitleCtrl, 'Title'),
                    _FieldDef(_bMessageCtrl, 'Message', maxLines: 3),
                    _FieldDef(_bImageCtrl, 'Image URL (optional)'),
                  ],
                  buttonLabel: 'Send Broadcast',
                  onSend: _sendBroadcast,
                ),
                _buildTab(
                  title: 'Send to Specific User',
                  fields: [
                    _FieldDef(_uIdCtrl, 'User ID'),
                    _FieldDef(_uTitleCtrl, 'Title'),
                    _FieldDef(_uMessageCtrl, 'Message', maxLines: 3),
                  ],
                  buttonLabel: 'Send Notification',
                  onSend: _sendToUser,
                ),
                _buildTab(
                  title: 'Test Notification',
                  fields: [
                    _FieldDef(_tTokenCtrl, 'Device Token', maxLines: 2),
                    _FieldDef(_tTitleCtrl, 'Title'),
                    _FieldDef(_tMessageCtrl, 'Message', maxLines: 3),
                  ],
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
    required String buttonLabel,
    required VoidCallback onSend,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
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
                    decoration: InputDecoration(labelText: f.label),
                    maxLines: f.maxLines,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldDef {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _FieldDef(this.controller, this.label, {this.maxLines = 1});
}
