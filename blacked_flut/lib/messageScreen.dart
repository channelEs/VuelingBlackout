import 'package:blacked_flut/components/protocol.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _controller = TextEditingController();
  final _messageController = TextEditingController();
  final _db = Localstore.instance;
  String _flightNumber = '';
  bool _readyCheck = false;

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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

              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "* To send a global message, leave this field empty",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(128, 0, 0, 0),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: Color.fromARGB(140, 0, 0, 0),
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: "Your flight number, e.g. VY3219",
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(128, 0, 0, 0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 5.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(128, 0, 0, 0),
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(128, 0, 0, 0),
                            width: 2.0,
                          ),
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.flight_takeoff,
                                color: Color.fromARGB(128, 0, 0, 0),
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                margin: const EdgeInsets.only(left: 8.0),
                                color: const Color.fromARGB(128, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _flightNumber = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _messageController,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Write your message here...",
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(128, 0, 0, 0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(128, 0, 0, 0),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _readyCheck,
                          onChanged: (value) {
                            setState(() {
                              _readyCheck = value ?? false;
                            });
                          },
                        ),
                        // Espacio pequeño entre el checkbox y el texto
                        const Expanded(
                          child: Text(
                            "I am sure to send this message",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_readyCheck) {
                            return;
                          }

                          if (_flightNumber.isEmpty) {
                            return;
                          }

                          if (_messageController.text.isEmpty) {
                            return;
                          }

                          int flightNumber = int.parse(
                            _flightNumber.substring(2),
                          );

                          String text = _messageController.text;
                          Protocol.initialize(flightNumber);
                          Protocol.sendMessage(text);
                        },
                        /* onPressed:
                            _readyCheck
                                ? () async {
                                  await _db
                                      .collection('flights')
                                      .doc('my_flight')
                                      .set({'flight_number': _flightNumber});
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PostScreen(
                                            flightId: _flightNumber,
                                          ),
                                    ),
                                  );
                                }
                                : null, */
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCB03),
                          foregroundColor: const Color(0xFF505047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'HammersmithOne',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
