import 'package:blacked_flut/ble.dart';
import 'package:blacked_flut/ble_dries.dart';
import 'package:blacked_flut/ble_stateful.dart';
import 'package:blacked_flut/services/peripheral_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PeripheralService _peripheralService = PeripheralService();
  static const platform = MethodChannel('com.example.blePeripheral');
  String _lastReceived = "No data received yet";
  String _lastSent = "No data sent yet";

  void _startPeripheral() async {
    await _peripheralService.startPeripheral();
  }

  @override
  void initState() {
    super.initState();
    _startPeripheral();
  }

  Future<void> writeCharacteristic(String data) async {
    try {
      final result = await platform.invokeMethod('writeCharacteristic', {"data": data});
      setState(() {
        _lastSent = data;
      });
      print(result); // Write successful
    } on PlatformException catch (e) {
      print("Failed to write to characteristic: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BleManagerWidget(actAsPeripheral: false),
            Text("---------------------f"),
            Text("Peripheral is running..."),
            SizedBox(height: 20),
            Text("Last Sent: $_lastSent"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example: writing the "Device Count" to the peripheral
                writeCharacteristic("DeviceCount: 6");
              },
              child: Text("Write to Peripheral"),
            ),
            SizedBox(height: 20),
            Text("Last Received: $_lastReceived"),
            // BleDriesWidget(),
          ],
        ),
      ),
    );
  }
}
