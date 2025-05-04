import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleManagerWidget extends StatefulWidget {
  final bool actAsPeripheral;
  const BleManagerWidget({super.key, required this.actAsPeripheral});

  @override
  State<BleManagerWidget> createState() => _BleManagerWidgetState();
}

class _BleManagerWidgetState extends State<BleManagerWidget> {
  // static Uuid APP_UUID_0 = Uuid.parse("bf27730d-860a-4e09-889c-2d8b6a9e0fe7");
  // static Uuid APP_UUID_RX = Uuid.parse("00002A18-0000-1000-8000-00805F9B34FB");
  // static Uuid APP_UUID_TX = Uuid.parse("00002A18-0000-1000-8000-00805F9B34FB");
  static final Uuid APP_UUID_0 = Uuid.parse("bf27730d-860a-4e09-889c-2d8b6a9e0fe7");
  static final Uuid APP_UUID_RX = Uuid.parse("bf27730d-860a-4e09-889c-2d8b6a9e0fe8"); // RX Characteristic
  static final Uuid APP_UUID_TX = Uuid.parse("bf27730d-860a-4e09-889c-2d8b6a9e0fe9"); // TX Characteristic

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  DiscoveredDevice? _device;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  Stream<List<int>>? _charSub;
  QualifiedCharacteristic? _rxCharacteristic;
  QualifiedCharacteristic? _txCharacteristic;
  Stream<ConnectionStateUpdate>? _currentConnectionStream;

  bool _isConnected = false;
  bool _isScanning = false;
  bool _isAdvertising = false;

  String _lastReceived = "";
  String _lastSent = "";
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
    _initAdvertise();
    _doScan();
    // if (widget.actAsPeripheral) {
    //   _initAdvertise();
    // } else {
    //   _doScan();
    // }
  }

  void _initAdvertise() async {
    await BlePeripheral.initialize();

    await BlePeripheral.addService(
      BleService(
        uuid: APP_UUID_0.toString(),
        primary: true,
        characteristics: [
          BleCharacteristic(
            uuid: APP_UUID_RX.toString(), // e.g., 0fe8
            properties: [
              CharacteristicProperties.write.index,
              CharacteristicProperties.read.index,
              ],
            permissions: [
              AttributePermissions.readable.index,
              AttributePermissions.writeable.index,
            ],
          ),
          BleCharacteristic(
            uuid: APP_UUID_TX.toString(), // e.g., 0fe9
            properties: [
              CharacteristicProperties.read.index,
              CharacteristicProperties.notify.index,
              CharacteristicProperties.write.index
            ],
            permissions: [
              AttributePermissions.readable.index,
              AttributePermissions.writeable.index,
            ],
            value: utf8.encode("DeviceCount: 0")
          ),
        ],
      ),
    );

    await BlePeripheral.startAdvertising(
      services: [APP_UUID_0.toString()],
      localName: getRandomString(8),
      manufacturerData: ManufacturerData(
        manufacturerId: 0xFF,
        data: utf8.encode("HELLO"),
      ),
      addManufacturerDataInScanResponse: true,
    );

    setState(() {
      _isAdvertising = true;
    });
  }

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );

  void _sendAdvertising() async {
    await BlePeripheral.startAdvertising(
      services: [APP_UUID_0.toString()],
      localName: getRandomString(8),
      manufacturerData: ManufacturerData(
        manufacturerId: 0xFF,
        data: utf8.encode("HELLO"),
      ),
      addManufacturerDataInScanResponse: true,
    );
  }

  void _doScan() {
    //    if (_isScanning) return;
    _isScanning = true;
    setState(() {});

    _scanSub = _ble.scanForDevices(withServices: [APP_UUID_0]).listen((
      device,
    ) async {
      if (_device == null) {
        debugPrint("Scanned");
        _device = device;
        _lastReceived = utf8.decode(device.manufacturerData.sublist(2));
        setState(() {});

        _connect();
      }
    });
  }

  void _connect() async {
    if (_device == null) return;
    await _connSub?.cancel();
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint("[BLE_Log] start connection || info: ${_device!.id}");
    _currentConnectionStream = _ble
    .connectToDevice(
      id: _device!.id,
      servicesWithCharacteristicsToDiscover: {
        APP_UUID_0: [
          APP_UUID_RX,
          APP_UUID_TX,
        ]
      },
      connectionTimeout: const Duration(seconds: 5),
    );
    debugPrint("[BLE_Log] start connection");
    setState(() {});
    _connSub = _currentConnectionStream!.listen((event) async {
      debugPrint("BLE connection state: ${event.connectionState.toString()}");
      switch (event.connectionState) {
        case DeviceConnectionState.connected:
          debugPrint("Connected");
          /*
          _txCharacteristic = QualifiedCharacteristic(
            serviceId: APP_UUID_0,
            characteristicId: APP_UUID_TX,
            deviceId: _device!.id,
          );
          _rxCharacteristic = QualifiedCharacteristic(
            serviceId: APP_UUID_0,
            characteristicId: APP_UUID_RX,
            deviceId: _device!.id,
          );
          */
          await _assignCharacteristics();
          _subscribeCharacteristic();
          // _subscribeCharacteristic();

          setState(() => _isConnected = true);
          break;

        case DeviceConnectionState.disconnected:
          debugPrint("[BLE_Log] disconneceted device: ${_device!.id}");
        case DeviceConnectionState.disconnecting:
          debugPrint("[BLE_Log] disconnecting device: ${_device!.id}");
          setState(() => _isConnected = false);
          break;
        default:
          break;
      }
    },
    onError: (e) {
      debugPrint("Connection failed: $e");
    },
    );
  }

  Future<void> _assignCharacteristics() async {
    final services = await _ble.getDiscoveredServices(_device!.id);

    for (var service in services) {
      debugPrint("[BL_Log] Service: ${service.id}");
      if (service.id == APP_UUID_0) {
        debugPrint("[BL_Log] IN SERVICE: ${service.id}");
        for (var char in service.characteristics) {
          debugPrint("[BL_Log] characteristic: ${char.id}");
        }
        final tx = service.characteristics.firstWhere(
          (c) => c.id == APP_UUID_TX,
          orElse: () => throw Exception("TX not found"),
        );

        final rx = service.characteristics.firstWhere(
          (c) => c.id == APP_UUID_RX,
          orElse: () => throw Exception("RX not found"),
        );
        debugPrint("[BL_Log] IN SERVICE: ${service.id}");

        setState(() {
          _txCharacteristic = QualifiedCharacteristic(
            characteristicId: tx.id,
            serviceId: service.id,
            deviceId: _device!.id,
          );

          _rxCharacteristic = QualifiedCharacteristic(
            characteristicId: rx.id,
            serviceId: service.id,
            deviceId: _device!.id,
          );
        });
      }
    }
  }


  void _subscribeCharacteristic() async {
    // await Future.delayed(Duration(seconds: 3));
    _charSub = _ble.subscribeToCharacteristic(_txCharacteristic!);
    debugPrint("[BLE_Log] subs characteristic result: ${_charSub.toString()}");
    _charSub!.listen(
      (data) {
        debugPrint("[READED BLE] Subscription LISTENING || data: ${utf8.decode(data)}");
        setState(() {
          _lastReceived = utf8.decode(data);
        });
      },
      onError: (e) {
        debugPrint("Subscription failed: $e");
      },
    );
  }

  Future<void> _writeCharacteristic() async {
    if (_rxCharacteristic == null) return;

    _count += 1;
    final data = utf8.encode("DeviceCount: $_count");

    try {
      await _ble.writeCharacteristicWithoutResponse(
        _rxCharacteristic!,
        value: data,
      );
      debugPrint("[BLE] Write successful to RX characteristic: $data || into the rx: ${_rxCharacteristic!.characteristicId}");
      setState(() => _lastSent = "DeviceCount: $_count");
      await Future.delayed(Duration(milliseconds: 100)); // Adjust timing as necessary

      _readChar();
    } catch (e) {
      debugPrint("Write error: $e");
    }
  }

  void _readChar() async
  {
    if (_rxCharacteristic == null) return;
    try {
      final response = await _ble.readCharacteristic(
        _rxCharacteristic!
      );
      debugPrint("[BLE] READ successful to RX characteristic: $response || into the rx: ${_rxCharacteristic!.characteristicId}");
      setState(() => _lastReceived = String.fromCharCodes(response));

    } catch (e) {
      debugPrint("[BLE] Read error: $e");
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("IS PERIHPERAL: ${widget.actAsPeripheral}"),
        Text("Connected: $_isConnected"),
        Text("Advertising: $_isAdvertising"),
        Text("Last Received: $_lastReceived"),
        Text("Last Sent: $_lastSent"),
        Text("Is scanning: $_isScanning"),
        const SizedBox(height: 16),
        if (_isAdvertising)
          ElevatedButton(
            onPressed: _readChar,
            child: const Text("READ"),
          ),
        if (_isAdvertising)
          ElevatedButton(
            onPressed: _writeCharacteristic,
            child: const Text("Send Message"),
          ),
      ],
    );
  }
}
