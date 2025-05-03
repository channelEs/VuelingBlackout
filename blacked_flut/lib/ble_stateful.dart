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
  static Uuid APP_UUID_0 = Uuid.parse("bf27730d-860a-4e09-889c-2d8b6a9e0fe7");
  static Uuid APP_UUID_RX = Uuid.parse("00002A18-0000-1000-8000-00805F9B34FB");
  static Uuid APP_UUID_TX = Uuid.parse("00002A18-0000-1000-8000-00805F9B34FB");

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  DiscoveredDevice? _device;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  Stream<List<int>>? _charSub;
  QualifiedCharacteristic? _rxCharacteristic;
  QualifiedCharacteristic? _txCharacteristic;

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

    var notificationDescriptor = BleDescriptor(
      uuid: "00002908-0000-1000-8000-00805F9B34FB",
      value: Uint8List.fromList([0, 1]),
      permissions: [
        AttributePermissions.readable.index,
        AttributePermissions.writeable.index,
      ],
    );

    await BlePeripheral.addService(
      BleService(
        uuid: APP_UUID_0.toString(),
        primary: true,
        characteristics: [
          BleCharacteristic(
            uuid: APP_UUID_RX.toString(),
            properties: [
              CharacteristicProperties.read.index,
              CharacteristicProperties.notify.index,
              CharacteristicProperties.write.index,
            ],
            descriptors: [notificationDescriptor],
            value: null,
            permissions: [
              AttributePermissions.readable.index,
              AttributePermissions.writeable.index,
            ],
          ),
        ],
      ),
    );

    _sendAdvertising();

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
        /*
            
            _txCharacteristic = QualifiedCharacteristic(
              serviceId: Uuid.parse(APP_UUID_0),
              characteristicId: Uuid.parse(APP_UUID2),
              deviceId: _device!.id,
            );
            _subscribeCharacteristic();
            */
      }
    });
  }

  void _connect() {
    if (_device == null) return;

    _connSub = _ble
        .connectToAdvertisingDevice(
          id: _device!.id,
          prescanDuration: Duration(seconds: 1),
          withServices: [APP_UUID_0, APP_UUID_RX, APP_UUID_TX],
        )
        .listen(
          (event) {
            switch (event.connectionState) {
              case DeviceConnectionState.connected:
                debugPrint("Connected");
                _txCharacteristic = QualifiedCharacteristic(
                  serviceId: APP_UUID_0,
                  characteristicId: APP_UUID_TX,
                  deviceId: _device!.id,
                );
                _subscribeCharacteristic();
                _rxCharacteristic = QualifiedCharacteristic(
                  serviceId: APP_UUID_0,
                  characteristicId: APP_UUID_RX,
                  deviceId: _device!.id,
                );

                setState(() => _isConnected = true);
                break;

              case DeviceConnectionState.disconnected:
              case DeviceConnectionState.disconnecting:
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

  void _subscribeCharacteristic() async {
    if (_txCharacteristic == null) return;
    await Future.delayed(Duration(seconds: 3));
    _charSub = _ble.subscribeToCharacteristic(_txCharacteristic!);
    debugPrint(_charSub.toString());
    _charSub!.listen(
      (data) {
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
    if (_txCharacteristic == null) return;

    _count += 1;
    final data = utf8.encode("Count: $_count");
    try {
      await _ble.writeCharacteristicWithoutResponse(
        _rxCharacteristic!,
        value: data,
      );
      setState(() => _lastSent = "Count: $_count");
    } catch (e) {
      debugPrint("Write error: $e");
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
            onPressed: _sendAdvertising,
            child: const Text("Send Advertising"),
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
