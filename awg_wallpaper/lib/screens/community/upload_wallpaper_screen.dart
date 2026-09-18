import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../services/api_service.dart';
import '../../services/community_upload_service.dart';
import '../../utils/creator_helper.dart';

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
  int? _imageWidth;
  int? _imageHeight;
  int? _fileSizeBytes;
  String? _validationError;
  bool _isValidating = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final size = await file.length();
    setState(() {
      _selectedFile = file;
      _fileSizeBytes = size;
      _validationError = null;
      _isValidating = true;
    });

    try {
      final decoded = await _uploadService.validateImage(file);
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationError = null;
          _imageWidth = decoded.width;
          _imageHeight = decoded.height;
        });
      }
    } on UploadValidationException catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationError = e.message;
          _selectedFile = null;
          _imageWidth = null;
          _imageHeight = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationError = 'Could not process this image. Try another.';
          _selectedFile = null;
          _imageWidth = null;
          _imageHeight = null;
        });
      }
    }
  }

  void _clearSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFile = null;
      _imageWidth = null;
      _imageHeight = null;
      _fileSizeBytes = null;
      _validationError = null;
    });
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      _showError('Please select a wallpaper image first.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isUploading = true;
    });

    try {
      // Re-validate and get decoded dimensions
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

      await CreatorHelper.setCreatorStatus(true);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text(
                  'Wallpaper shared with Collective!',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────────
            _buildHeader(isDark),

            // ─── Scrollable Content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker & Preview Card
                    _buildImagePickerCard(isDark),

                    // Validation Error Banner
                    if (_validationError != null) ...[
                      const SizedBox(height: 12),
                      _buildValidationErrorBanner(),
                    ],

                    const SizedBox(height: 24),

                    // Wallpaper Title Input
                    _buildSectionHeader(
                      icon: Icons.title_rounded,
                      title: 'Title',
                      badge: 'Optional',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'Give your wallpaper an inspiring name...',
                      icon: Icons.edit_rounded,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),

                    // Description / Story Input
                    _buildSectionHeader(
                      icon: Icons.notes_rounded,
                      title: 'Description',
                      badge: 'Optional',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descController,
                      hint: 'Share details, inspiration, or how this art was created...',
                      icon: Icons.short_text_rounded,
                      maxLines: 3,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Guidelines / Quality Note
                    _buildGuidelinesCard(isDark),

                    const SizedBox(height: 28),

                    // Primary Action Button
                    _buildUploadButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final canShare = _selectedFile != null && !_isUploading && !_isValidating;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.getTextPrimary(isDark),
                  size: 20,
                ),
              ),
            ),
          ),

          // Title
          Column(
            children: [
              Text(
                'SHARE WALLPAPER',
                style: GoogleFonts.poppins(
                  color: AppTheme.getTextPrimary(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SoftSky Collective Studio',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Action Button on Top Right
          if (canShare)
            GestureDetector(
              onTap: _upload,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ─── Image Picker / Preview Card ──────────────────────────────────────────

  Widget _buildImagePickerCard(bool isDark) {
    if (_isValidating) {
      return Container(
        width: double.infinity,
        height: 360,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Checking Image Resolution...',
                style: GoogleFonts.inter(
                  color: AppTheme.getTextPrimary(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ensuring 1080×1920 HD requirement',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(isDark),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedFile != null) {
      final sizeMb = _fileSizeBytes != null
          ? (_fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)
          : null;

      return Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image Preview
            Image.file(
              _selectedFile!,
              fit: BoxFit.cover,
            ),

            // Top vignette gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom vignette gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 110,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top controls: Quality Badge (Left) and Actions (Right)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Validated badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.greenAccent,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _imageWidth != null && _imageHeight != null
                              ? '$_imageWidth×$_imageHeight'
                              : 'HD Ready',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Change & Delete buttons
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isUploading ? null : _clearSelection,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom details
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sizeMb != null ? 'File Size: $sizeMb MB' : 'Portrait Wallpaper',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Ready to Share',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default: Empty selection prompt
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 340,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Elevated Icon
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.25),
                    AppTheme.primary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppTheme.primary,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Select Portrait Wallpaper',
              style: GoogleFonts.inter(
                color: AppTheme.getTextPrimary(isDark),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to choose high resolution image from gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.getTextSecondary(isDark),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            // Specs badges row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSpecChip('1080×1920 min', isDark),
                const SizedBox(width: 8),
                _buildSpecChip('Up to 20 MB', isDark),
                const SizedBox(width: 8),
                _buildSpecChip('Portrait', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.getTextSecondary(isDark),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Validation Error Banner ──────────────────────────────────────────────

  Widget _buildValidationErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _validationError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String badge,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppTheme.getTextPrimary(isDark),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: AppTheme.getTextSecondary(isDark),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Text Fields ──────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: AppTheme.getTextPrimary(isDark), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.getTextMuted(isDark),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: AppTheme.getTextSecondary(isDark),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── Guidelines Card ──────────────────────────────────────────────────────

  Widget _buildGuidelinesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator Guidelines',
                  style: TextStyle(
                    color: AppTheme.getTextPrimary(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please share high-resolution, original or royalty-free portrait art without watermarks. Wallpapers become instantly discoverable in the Collective.',
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(isDark),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upload Button ────────────────────────────────────────────────────────

  Widget _buildUploadButton() {
    final isReady = _selectedFile != null && !_isValidating && !_isUploading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isReady ? _upload : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Sharing to Collective...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    color: isReady ? Colors.white : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share with Collective',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isReady ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
