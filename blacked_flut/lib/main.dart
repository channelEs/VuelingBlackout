import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _ble = FlutterReactiveBle();
  DiscoveredDevice? _device;
  String _connectionStatus = 'idle';
  String _latestValue = '';
  bool _isReading = false;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _charSub;

  // Replace with your BLE service & characteristic UUIDs
  final _serviceUuid = Uuid.parse("bf27730d-860a-4e09-889c-2d8b6a9e0fe7");
  final _charUuid = Uuid.parse("00002A18-0000-1000-8000-00805F9B34FB");

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    _scanSub = _ble.scanForDevices(
      withServices: [_serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (_device == null) {
        setState(() => _device = device);
        _scanSub?.cancel();
        _connect();
      }
    }, onError: (e) {
      setState(() => _connectionStatus = 'scan error: $e');
    });
  }

  void _connect() {
    if (_device == null) return;
    setState(() => _connectionStatus = 'connecting to ${_device!.name}');

    _connSub = _ble.connectToDevice(
      id: _device!.id,
      connectionTimeout: const Duration(seconds: 5),
    ).listen((update) {
      setState(() => _connectionStatus = update.connectionState.toString());

      if (update.connectionState == DeviceConnectionState.connected) {
        _subscribeCharacteristic();
      }
    }, onError: (e) {
      setState(() => _connectionStatus = 'connection error: $e');
    });
  }

  void _subscribeCharacteristic() {
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _charUuid,
      deviceId: _device!.id,
    );

    _charSub = _ble.subscribeToCharacteristic(characteristic).listen((data) {
      final str = utf8.decode(data);
      setState(() => _latestValue = str);
    }, onError: (e) {
      setState(() => _latestValue = 'sub error: $e');
    });
  }

  Future<void> _readCharacteristic() async {
    if (_device == null) return;
    setState(() => _isReading = true);

    try {
      final characteristic = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _charUuid,
        deviceId: _device!.id,
      );

      final value = await _ble.readCharacteristic(characteristic);
      final str = utf8.decode(value);

      setState(() => _latestValue = 'Read: $str');
    } catch (e) {
      setState(() => _latestValue = 'read error: $e');
    } finally {
      setState(() => _isReading = false);
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _charSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${_device?.name ?? 'scanning...'}'),
            const SizedBox(height: 8),
            Text('Status: $_connectionStatus'),
            const Divider(),
            const Text('Latest characteristic value:'),
            const SizedBox(height: 8),
            Text(_latestValue, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isReading ? null : _readCharacteristic,
              child: _isReading
                  ? const CircularProgressIndicator()
                  : const Text('Read Value'),
            ),
          ],
        ),
      ),
    );
  }
}
