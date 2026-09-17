import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../services/api_service.dart';
import '../../services/community_upload_service.dart';

class UploadWallpaperScreen extends StatefulWidget {
  const UploadWallpaperScreen({super.key});

  @override
  State<UploadWallpaperScreen> createState() => _UploadWallpaperScreenState();
}

class _UploadWallpaperScreenState extends State<UploadWallpaperScreen> {
  final _picker = ImagePicker();
  final _uploadService = CommunityUploadService();
  final _api = ApiService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _selectedFile;
  String? _validationError;
  bool _isValidating = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _selectedFile = file;
      _validationError = null;
      _isValidating = true;
    });

    try {
      await _uploadService.validateImage(file);
      setState(() {
        _isValidating = false;
        _validationError = null;
      });
    } on UploadValidationException catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = e.message;
        _selectedFile = null;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = 'Could not process this image. Try another.';
        _selectedFile = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      _showError('Please select an image first.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      // Re-validate and get decoded image
      final decoded = await _uploadService.validateImage(_selectedFile!);

      // Upload directly to custom hosting server
      final data = await _api.uploadCommunityPostFile(
        file: _selectedFile!,
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        width: decoded.width,
        height: decoded.height,
      );

      final post =
          CommunityPost.fromJson(data['post'] as Map<String, dynamic>);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wallpaper uploaded successfully! 🎉'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, post);
      }
    } on UploadValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      debugPrint('Wallpaper upload exception: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackground(isDark),
        title: const Text('Upload Wallpaper'),
        actions: [
          if (_selectedFile != null && !_isUploading)
            TextButton(
              onPressed: _upload,
              child: const Text(
                'Share',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker area
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _validationError != null
                        ? AppTheme.error
                        : _selectedFile != null
                            ? AppTheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImageArea(),
              ),
            ),

            // Validation error
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppTheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: const TextStyle(
                          color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            // Requirement hint
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Colors.grey.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Minimum resolution: 1080 × 1920 px • Max 20 MB',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withValues(alpha: 0.6)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Upload progress
            if (_isUploading) ...[
              Text(
                'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
            ],

            // Title field
            _buildLabel('Title (optional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'Give your wallpaper a title...',
            ),

            const SizedBox(height: 20),

            // Description field
            _buildLabel('Description (optional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descController,
              hint: 'Share the story behind this wallpaper...',
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isUploading || _selectedFile == null || _isValidating)
                    ? null
                    : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor:
                      AppTheme.primary.withValues(alpha: 0.4),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Share with Collective',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (_isValidating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 12),
            Text('Checking image quality...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_selectedFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedFile!, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: Colors.grey.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text(
          'Tap to select a wallpaper',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          'Gallery only',
          style:
              TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
