import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart'; // Import the PocketBaseService

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final PocketBaseService pbService = PocketBaseService(); // Use your service
  RecordModel? event;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    try {
      // Fetch event details (without relying on expand)
      final result = await pbService.pb.collection('events').getOne(
        widget.eventId,
      );
      print('Event data: ${result.toJson()}');  // Log the event data for debugging

      setState(() {
        event = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching event details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load event details')),
      );
    }

    // Extract image filenames from the 'Image' field
    final List<String> imageFiles = (event!.data['Image'] as List<dynamic>).cast<String>();

    return Scaffold(
      appBar: AppBar(
        title: Text(event!.data['title'] ?? 'Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                event!.data['description'] ?? 'No description',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (imageFiles.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: imageFiles.length,
                itemBuilder: (context, index) {
                  final imageFile = imageFiles[index];
                  final imageUrl = '${pbService.pb.baseUrl}/api/files/${event!.collectionId}/${event!.id}/$imageFile';
                  
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      print('Failed URL: $imageUrl');
                      return const Center(child: Icon(Icons.error));
                    },
                  );
                },
              )
            else
              const Center(child: Text('No images available')),
          ],
        ),
      ),
    );
  }
}
