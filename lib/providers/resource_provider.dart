import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/resource.dart';
import '../services/resource_service.dart';
import '../services/text_extraction_service.dart';

class ResourceProvider extends ChangeNotifier {
  final ResourceService _resourceService = ResourceService();
  final TextExtractionService _textExtractionService = TextExtractionService();

  List<Resource> _resources = [];
  List<String> _availableTags = [];
  String? _selectedTag;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  List<Resource> get resources => _resources;
  List<Resource> get filteredResources {
    if (_selectedTag == null || _selectedTag!.isEmpty) return _resources;
    return _resources
        .where((r) => r.tags.any((t) => t.toLowerCase() == _selectedTag!.toLowerCase()))
        .toList();
  }
  List<String> get availableTags => _availableTags;
  String? get selectedTag => _selectedTag;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  Future<void> loadResources(String subjectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _resources = await _resourceService.getResources(subjectId);
      _availableTags = await _resourceService.getAllTags(subjectId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Resource?> addResource({
    required String subjectId,
    required String title,
    required String userId,
    String? description,
    String? linkUrl,
    String? fileName,
    Uint8List? fileBytes,
    List<String> tags = const [],
  }) async {
    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      String? fileUrl;
      String? fileType;
      int? fileSize;

      if (fileBytes != null && fileName != null) {
        fileUrl = await _resourceService.uploadFile(
          subjectId: subjectId,
          fileName: fileName,
          fileBytes: fileBytes,
        );
        fileType = fileName.split('.').last;
        fileSize = fileBytes.length;
      }

      final resource = await _resourceService.addResource(
        subjectId: subjectId,
        title: title,
        userId: userId,
        description: description,
        fileUrl: fileUrl,
        linkUrl: linkUrl,
        fileType: fileType,
        fileSize: fileSize,
        tags: tags,
      );

      _resources.insert(0, resource);
      _isUploading = false;
      notifyListeners();

      // Run text extraction (awaited so errors are caught)
      try {
        await _textExtractionService.extractAndStore(
          resourceId: resource.id,
          fileBytes: fileBytes,
          fileType: fileType,
          fileUrl: fileUrl,
          linkUrl: linkUrl,
          title: title,
          description: description,
        );
      } catch (_) {
        // Non-critical: resource is saved even if extraction fails
      }

      return resource;
    } catch (e) {
      _error = e.toString();
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  /// Retry text extraction for all pending/failed/missing resources in a subject
  Future<int> retryFailedExtractions(String subjectId) async {
    try {
      final count =
          await _textExtractionService.extractMissingResources(subjectId);
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteResource(String resourceId) async {
    try {
      await _resourceService.deleteResource(resourceId);
      _resources.removeWhere((r) => r.id == resourceId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
