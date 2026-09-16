import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Minimum resolution required for community wallpaper uploads
const int kMinUploadWidth = 1080;
const int kMinUploadHeight = 1920;

/// Maximum file size (20 MB)
const int kMaxFileSizeBytes = 20 * 1024 * 1024;

class UploadValidationException implements Exception {
  final String message;
  UploadValidationException(this.message);
  @override
  String toString() => message;
}

class CommunityUploadService {
  static final CommunityUploadService _instance = CommunityUploadService._internal();
  factory CommunityUploadService() => _instance;
  CommunityUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Validates image resolution and file size.
  /// Returns decoded image on success or throws [UploadValidationException].
  Future<img.Image> validateImage(File file) async {
    // Check file size
    final size = await file.length();
    if (size > kMaxFileSizeBytes) {
      throw UploadValidationException(
          'Image is too large. Maximum allowed size is 20 MB.');
    }

    // Decode image to check dimensions
    final bytes = await file.readAsBytes();
    final decoded = await compute(_decodeImage, bytes);

    if (decoded == null) {
      throw UploadValidationException(
          'Could not read the image file. Please choose a valid image.');
    }

    if (decoded.width < kMinUploadWidth || decoded.height < kMinUploadHeight) {
      throw UploadValidationException(
          'Image resolution is too low. Please upload a wallpaper that is at least '
          '$kMinUploadWidth×$kMinUploadHeight pixels. '
          'Your image is ${decoded.width}×${decoded.height} pixels.');
    }

    return decoded;
  }

  /// Generates a thumbnail (400px wide) and returns its bytes.
  Future<Uint8List> generateThumbnail(img.Image original) async {
    return compute(_resizeImage, original);
  }

  /// Uploads the original image and thumbnail to Firebase Storage.
  /// Returns a map with 'imageUrl' and 'thumbnailUrl'.
  Future<Map<String, String>> uploadWallpaper(
    File file,
    img.Image decodedImage, {
    void Function(double progress)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final id = _uuid.v4();
    final originalPath = 'community/$uid/$id.jpg';
    final thumbPath = 'community/$uid/${id}_thumb.jpg';

    // Upload original
    final originalRef = _storage.ref(originalPath);
    final uploadTask = originalRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    uploadTask.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    await uploadTask;
    final imageUrl = await originalRef.getDownloadURL();

    // Generate and upload thumbnail
    String thumbnailUrl = imageUrl;
    try {
      final thumbBytes = await generateThumbnail(decodedImage);
      final thumbRef = _storage.ref(thumbPath);
      await thumbRef.putData(
        thumbBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      thumbnailUrl = await thumbRef.getDownloadURL();
    } catch (e) {
      debugPrint('Thumbnail generation failed, using original: $e');
    }

    return {
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'width': decodedImage.width.toString(),
      'height': decodedImage.height.toString(),
    };
  }

  /// Delete an image from Firebase Storage by its URL.
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Failed to delete from storage: $e');
    }
  }
}

// ─── Isolate helpers ─────────────────────────────────────────────────────────

img.Image? _decodeImage(Uint8List bytes) {
  return img.decodeImage(bytes);
}

Uint8List _resizeImage(img.Image source) {
  final thumb = img.copyResize(source, width: 400);
  return Uint8List.fromList(img.encodeJpg(thumb, quality: 80));
}
