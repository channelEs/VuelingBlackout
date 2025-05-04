import 'package:blacked_flut/ble.dart';
import 'package:blacked_flut/messageScreen.dart';
import 'package:blacked_flut/postScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:localstore/localstore.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Ble ble = Ble();
  final _db = Localstore.instance;
  //late String lastMessage;
  String _flightNumber = '';
  late TextEditingController _controller;

  void _incrementCounter() async {
    /* if (!Ble.isInitialized) {
      ble.initialize();
    }

    ble.messagesQueue.add("Hello");

    setState(() => {}); */
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _checkLocalStorage();
  }

  Future<void> _checkLocalStorage() async {
    final data = await _db.collection('flights').doc('my_flight').get();

    if (data != null && data.isNotEmpty) {
      // Hay datos → redirigir a otra página
      _controller.text = data['flight_number'] ?? '';
      _flightNumber = data['flight_number'];

      /* if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostScreen(flightId: _flightNumber),
          ),
        );
      } */
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Siempre liberar el controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //return MessageScreen();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset('assets/unblacked2.svg', height: 80),
              const Text(
                'lights off, keep vueling',
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF505047),
                  //Font hammersmith one
                  fontFamily: 'HammersmithOne',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _controller,
                style: TextStyle(
                  color: Colors.black.withAlpha(140),
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: "Your flight number, e.g. VY3219",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withAlpha(128),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 5.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.black.withAlpha(128),
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.black.withAlpha(128),
                      width: 2.0,
                    ),
                  ),
                  prefixIcon: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          color: Colors.black.withAlpha(128),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          margin: EdgeInsets.only(left: 8.0),
                          color: Colors.black.withAlpha(128),
                        ),
                      ],
                    ),
                  ),
                ),
                onChanged: (value) {
                  _flightNumber = value;
                },
              ),
              /* const SizedBox(height: 40),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Eg: Smith',
                ),
                onChanged: (value) {
                  _lastName = value;
                },
              ), */
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save the flight number to local storage
                    await _db.collection('flights').doc('my_flight').set({
                      'flight_number': _flightNumber,
                      //'last_name': _lastName,
                    });
                    // Retrieve the flight number from local storage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostScreen(flightId: _flightNumber),
                        // builder: (_) => MessageScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFCB03), // amarillo
                    foregroundColor: Color(0xFF505047), // texto
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12.0,
                      ), // bordes redondeados
                    ),
                    elevation: 1,
                  ),
                  child: Text(
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
