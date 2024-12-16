import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeImageUploadService {
  final SupabaseClient _supabase;
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  ChallengeImageUploadService({
    required SupabaseClient supabaseClient,
    required FirebaseDatabase database,
    required FirebaseAuth auth,
  })  : _supabase = supabaseClient,
        _database = database,
        _auth = auth;

  /// Uploads a challenge proof image with comprehensive validation and error handling
  Future<String?> uploadChallengeProofImage({
    required XFile imageFile,
    required String challengeId,
  }) async {
    try {
      // 1. User Authentication Check
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Authentication Error',
          'Please log in to upload a proof image',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      // 2. File Validation
      // Check file existence
      final file = File(imageFile.path);
      if (!await file.exists()) {
        Get.snackbar(
          'File Error',
          'Selected image file does not exist',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      // File size validation (10 MB limit)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        Get.snackbar(
          'Size Limit Exceeded',
          'Image must be less than 10 MB',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      // File type validation
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(fileExt)) {
        Get.snackbar(
          'Invalid File Type',
          'Only image files are allowed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      // 3. Ensure Supabase Storage Bucket Exists
      await _ensureStorageBucketExists('challenges');

      // 4. Generate Unique Filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${currentUser.uid}_$timestamp.$fileExt';
      final storagePath = 'proofs/challenge_proof/$challengeId/$fileName';

      // 5. Upload to Supabase Storage
      final uploadResponse = await _supabase.storage.from('challenges').upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(fileExt),
            ),
          );

      // 6. Get Public URL
      final publicUrl =
          _supabase.storage.from('challenges').getPublicUrl(storagePath);

      // 7. Save Metadata to Firebase Realtime Database
      await _database
          .ref('challenge_proofs/$challengeId/${currentUser.uid}')
          .set({
        'imageUrl': publicUrl,
        'uploadedAt': ServerValue.timestamp,
        'fileSize': fileSize,
        'fileType': fileExt,
      });

      // 8. Show Success Notification
      Get.snackbar(
        'Upload Successful',
        'Your challenge proof image has been uploaded',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return publicUrl;
    } on StorageException catch (storageError) {
      // Handle Supabase Storage specific errors
      print('Supabase Storage Error: ${storageError.message}');
      Get.snackbar(
        'Storage Error',
        'Failed to upload image to storage: ${storageError.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } on FirebaseException catch (firebaseError) {
      // Handle Firebase specific errors
      print('Firebase Error: ${firebaseError.message}');
      Get.snackbar(
        'Database Error',
        'Failed to save image metadata: ${firebaseError.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } catch (e) {
      // Handle any other unexpected errors
      print('Unexpected error during image upload: $e');
      Get.snackbar(
        'Upload Failed',
        'An unexpected error occurred while uploading the image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// Ensures the specified Supabase storage bucket exists
  Future<void> _ensureStorageBucketExists(String bucketName) async {
    try {
      // Try to list buckets to check if the bucket exists
      await _supabase.storage.listBuckets();
    } catch (e) {
      try {
        // If listing fails, attempt to create the bucket
        await _supabase.storage.createBucket(bucketName);
      } catch (createError) {
        print('Failed to create storage bucket: $createError');
        rethrow;
      }
    }
  }

  /// Determines the content type based on file extension
  String _getContentType(String fileExt) {
    switch (fileExt.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
