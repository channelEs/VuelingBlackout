import 'package:blacked_flut/components/message.dart';
import 'package:blacked_flut/components/protocol.dart';
import 'package:blacked_flut/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localstore/localstore.dart';

const List<Map<String, String>> data = [
  {
    'message':
        'Your flight has been delayed 30 mins. Your new departure time is 13:30',
    'date': '2025-01-01 12:00:00',
  },
  {
    'message':
        'Your flight has been cancelled. Please contact customer service.',
    'date': '2023-10-02 14:00:00',
  },
  {
    'message': 'Your flight is boarding now. Please proceed to gate 5.',
    'date': '2023-10-03 15:00:00',
  },
  {
    'message': 'Your flight has landed safely. Thank you for flying with us!',
    'date': '2023-10-04 16:00:00',
  },
  {
    'message':
        'Your flight has been delayed 30 mins. Your new departure time is 13:30',
    'date': '2025-01-01 12:00:00',
  },
  {
    'message':
        'Your flight has been cancelled. Please contact customer service.',
    'date': '2023-10-02 14:00:00',
  },
  {
    'message': 'Your flight is boarding now. Please proceed to gate 5.',
    'date': '2023-10-03 15:00:00',
  },
  {
    'message': 'Your flight has landed safely. Thank you for flying with us!',
    'date': '2023-10-04 16:00:00',
  },
];

class PostScreen extends StatefulWidget {
  final String flightId; // o cualquier tipo que necesites

  const PostScreen({super.key, required this.flightId});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

String timeAgo(DateTime date) {
  final Duration diff = DateTime.now().difference(date);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 30) {
    return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago';
  }
  return '${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() > 1 ? 's' : ''} ago';
}

Color getAccentColor(String message) {
  if (message.toLowerCase().contains('cancelled')) return Colors.red;
  if (message.toLowerCase().contains('delayed')) return Colors.orange;
  if (message.toLowerCase().contains('boarding')) return Colors.green;
  if (message.toLowerCase().contains('landed')) return Colors.blue;
  if (message.toLowerCase().contains('luggage')) return Colors.brown;
  return Colors.grey; // default
}

class _PostScreenState extends State<PostScreen> {
  late List<Map<String, String>> messages;

  @override
  void initState() {
    super.initState();
    messages = [];

    Protocol.setMessageCallback((Message message) {
      setState(() {
        messages.add(<String, String>{
          "message": message.content,
          "date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        });
      });
    });
    Protocol.initialize(3910);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Parte superior: título grande con fondo blanco
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relax,',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'keep the info vueling around.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Roboto',
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Parte inferior: fondo F4F1F1 con esquinas redondeadas
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFF4F1F1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(0, -4), // Hacia arriba
                    blurRadius: 5,
                  ),
                ],
              ),

              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    child: Text(
                      'Keep this screen open to receive critical information about your flight ${widget.flightId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 140,
                      ), // 👈 margen inferior

                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index]['message']!;
                        final date = DateTime.parse(messages[index]['date']!);
                        final color = getAccentColor(message);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 4, color: color),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeAgo(date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
        ],
      ),
      /* floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomNotification(context),
        child: const Icon(Icons.add),
      ), */
    );
  }
}
