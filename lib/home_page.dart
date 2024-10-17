import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'event_details_page.dart';
import 'event_edit_page.dart';
import 'pocketbase_service.dart';  // Import your PocketBaseService
import 'main.dart';  // To navigate back to the LoginPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PocketBaseService pbService = PocketBaseService(); // Use your service
  List<RecordModel> events = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await pbService.pb.collection('events').getList(
        page: 1,
        perPage: 20,
        expand: 'images', // Assuming you have an 'images' relation
      );
      setState(() {
        events = result.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching events: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await pbService.pb.collection('events').delete(id);
      fetchEvents(); // Refresh the list
    } catch (e) {
      setState(() {
        errorMessage = 'Error deleting event: $e';
      });
      print(errorMessage);
    }
  }

  Future<void> logout() async {
    pbService.pb.authStore.clear(); // Clear the authentication token
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to login page
    );
  }

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Logout button
            onPressed: logout, // Call the logout method
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : events.isEmpty
                  ? const Center(child: Text('No events found.'))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          title: Text(event.data['title'] ?? 'No Title'),
                          subtitle: Text(event.data['description'] ?? 'No Description'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailsPage(eventId: event.id),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventEditPage(eventId: event.id),
                                    ),
                                  ).then((_) => fetchEvents());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => deleteEvent(event.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventEditPage(),
            ),
          ).then((_) => fetchEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
