import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;  // Import the correct http package
import 'dart:io';
import 'pocketbase_service.dart';  // Import the PocketBaseService

class EventEditPage extends StatefulWidget {
  final String? eventId;

  const EventEditPage({Key? key, this.eventId}) : super(key: key);

  @override
  _EventEditPageState createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final PocketBaseService pbService = PocketBaseService(); // Use the service instead of hardcoded PocketBase
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<XFile> _imageFiles = []; // New images to be uploaded
  List<String> _existingImageFiles = []; // Existing images
  List<String> _imagesToDelete = []; // Track images marked for deletion
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _fetchEventDetails();
    }
  }

  Future<void> _fetchEventDetails() async {
    try {
      final event = await pbService.pb.collection('events').getOne(widget.eventId!);
      setState(() {
        titleController.text = event.data['title'] ?? '';
        descriptionController.text = event.data['description'] ?? '';

        // Load existing images
        if (event.data['Image'] != null) {
          _existingImageFiles = (event.data['Image'] as List<dynamic>).cast<String>();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching event details: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles.addAll(pickedFiles);
      });
    }
  }

  // Method to update image field in PocketBase
  Future<void> _updateImageField(List<String> updatedImages) async {
    try {
      await pbService.pb.collection('events').update(
        widget.eventId!,
        body: {
          'Image': updatedImages,  // Update the Image field with remaining images
        },
      );
      print("Updated image field with: $updatedImages");
    } catch (e) {
      print("Failed to update image field: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating image field: $e')),
      );
    }
  }

  Future<void> _saveEvent() async {
    setState(() => _isLoading = true);
    try {
      // First, update the Image field to remove the images marked for deletion
      final List<String> remainingImages = List.from(_existingImageFiles);  // Copy of remaining images
      for (String imageName in _imagesToDelete) {
        remainingImages.remove(imageName);  // Remove images marked for deletion
      }
      await _updateImageField(remainingImages);  // Update the record with remaining images

      // Now upload new files
      final List<http.MultipartFile> multipartFiles = await Future.wait(
        _imageFiles.map((file) => http.MultipartFile.fromPath('Image', file.path))
      );

      RecordModel event;
      if (widget.eventId != null) {
        // Update existing event
        event = await pbService.pb.collection('events').update(
          widget.eventId!,
          body: {
            'title': titleController.text,
            'description': descriptionController.text,
          },
          files: multipartFiles,  // Use the awaited list of files
        );
      } else {
        // Create new event
        event = await pbService.pb.collection('events').create(
          body: {
            'title': titleController.text,
            'description': descriptionController.text,
          },
          files: multipartFiles,  // Use the awaited list of files
        );
      }

      // After saving event, go back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _markImageForDeletion(String imageName) {
    setState(() {
      _existingImageFiles.remove(imageName); // Remove from the current display list
      _imagesToDelete.add(imageName); // Add to the list of images to delete
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveEvent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImages,
                    child: const Text('Add Images'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Display existing images with delete icon
                  if (_existingImageFiles.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _existingImageFiles.length,
                      itemBuilder: (context, index) {
                        final imageName = _existingImageFiles[index];
                        final imageUrl = '${pbService.pb.baseUrl}/api/files/events/${widget.eventId}/$imageName';
                        return Stack(
                          children: [
                            Image.network(imageUrl, fit: BoxFit.cover),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _markImageForDeletion(imageName), // Mark for deletion
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // Display newly picked images
                  if (_imageFiles.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(_imageFiles[index].path),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
