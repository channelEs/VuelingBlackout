import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleDriesWidget extends StatefulWidget {
  const BleDriesWidget({super.key});

  @override
  State<BleDriesWidget> createState() => _BleManagerWidgetState();
}

class _BleManagerWidgetState extends State<BleDriesWidget> {
  static const SERVICE_UUID = "bf27730d-860a-4e09-889c-2d8b6a9e0fe7";
  static const CHAR_UUID = "00002A18-0000-1000-8000-00805F9B34FB";

  late FlutterReactiveBle _ble;

  final Map<String, DiscoveredDevice> _peers = <String, DiscoveredDevice>{};

  bool _isScanning = false;
  bool _isAdvertising = false;

  String _myLocalName = "";

  @override
  void initState() {
    super.initState();

    _ble = FlutterReactiveBle();
    _initialize();
  }

  void _log(String text) => print("[ble] $text");

  Future<void> _initialize() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    _log("BLE permissions granted!");
    _myLocalName = getRandomString(5);

    await _ble.initialize();
    _log("BLE Initialized successfully!");

    _doScan();
    _initAdvertise();
  }

  void _initAdvertise() async {
    _log("Initializing BlePeripheral...");
    await BlePeripheral.initialize();
    _log("BlePeripheral initialized successfully!");

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
        uuid: SERVICE_UUID,
        primary: true,
        characteristics: [
          BleCharacteristic(
            uuid: CHAR_UUID,
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
    var manufacturerData = ManufacturerData(
      manufacturerId: 0xFF,
      data: utf8.encode(_myLocalName),
    );

    await BlePeripheral.startAdvertising(
      services: [SERVICE_UUID],
      localName: _myLocalName,

      manufacturerData: manufacturerData,
      addManufacturerDataInScanResponse: true,
    );

    setState(() {
      _isAdvertising = true;
    });

    _log("Service adversiting is now enabled");
  }

  void _doScan() {
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    _log("Scanning for nearby devices...");

    _ble.scanForDevices(withServices: [Uuid.parse(SERVICE_UUID)]).listen((
      device,
    ) {
      if (_peers.containsKey(device.id)) {
        _log("Device ${device.id} already in there!");
        return;
      }

      setState(() {
        _peers[device.id] = device;
      });

      _log("Added device ${device.name} (${device.id}) to peer list");
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peers = _peers.values.toList();
    return Column(
      children: [
        Text("I am: $_myLocalName"),
        Text("Found devices:"),
        ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: peers.length,
          itemBuilder: (context, index) {
            return Text("Peer ${peers[index].name} (${peers[index].id})");
          },
        ),
      ],
    );
  }
}
