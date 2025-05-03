import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class Ble {
  static const APP_UUID = "bf27730d-860a-4e09-889c-2d8b6a9e0fe7";
  static const APP_UUID2 = "00002A18-0000-1000-8000-00805F9B34FB";

  static bool isInitialized = false;
  static bool isAdvertising = false;
  static bool isScanning = false;

  late final FlutterReactiveBle flutterReactiveBle;
  late final Queue<String> messagesQueue;

  late String lastRecvMsg;
  late String lastRcvFrom;

  late String lastSndMsg;

  Ble() {
    flutterReactiveBle = FlutterReactiveBle();
    messagesQueue = Queue();

    lastRcvFrom = "";
    lastRecvMsg = "";

    lastSndMsg = "";
  }

  void initialize() {
    if (isInitialized) {
      return;
    }

    isInitialized = true;

    [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.locationWhenInUse,
    ].request().then((_) {
      doScan();
      initAdvertise();

      Timer.periodic(Duration(milliseconds: 1000), (timer) async {
        if (isAdvertising) {
          await BlePeripheral.stopAdvertising();
          isAdvertising = false;
        }

        if (messagesQueue.isNotEmpty) {
          String message = messagesQueue.removeFirst();
          log("Sending message: \"$message\"");
          doSend(message);
        }
      });
    });
  }

  void initAdvertise() async {
    log("Initializing BlePeripheral...");
    BlePeripheral.initialize();

    log("Adding services...");
    var notificationControlDescriptor = BleDescriptor(
      uuid: "00002908-0000-1000-8000-00805F9B34FB",
      value: Uint8List.fromList([0, 1]),
      permissions: [
        AttributePermissions.readable.index,
        AttributePermissions.writeable.index,
      ],
    );

    await BlePeripheral.addService(
      BleService(
        uuid: APP_UUID,
        primary: true,
        characteristics: [
          BleCharacteristic(
            uuid: APP_UUID2,
            properties: [
              CharacteristicProperties.read.index,
              CharacteristicProperties.notify.index,
              CharacteristicProperties.write.index,
            ],
            descriptors: [notificationControlDescriptor],
            value: null,
            permissions: [
              AttributePermissions.readable.index,
              AttributePermissions.writeable.index,
            ],
          ),
        ],
      ),
    );
  }

  void doScan() {
    if (isScanning) {
      return;
    }

    isScanning = true;
    log("Scanning nearby devices...");

    flutterReactiveBle.scanForDevices(withServices: [Uuid.parse(APP_UUID)]).listen((
      device,
    ) {
      log(
        "Received ${device.manufacturerData.length - 2} bytes from ${device.id} (${device.name}):\n${utf8.decode(device.manufacturerData.sublist(2))}",
      );

      lastRcvFrom = device.id;
      lastRecvMsg = utf8.decode(device.manufacturerData.sublist(2));
    });
  }

  void doSend(String message) async {
    Uint8List bytes = utf8.encode(message);
    if (bytes.length > 20) {
      log("ERROR: message $message is > 20 bytes");
      return;
    }
    var manufacturerData = ManufacturerData(manufacturerId: 0xFF, data: bytes);
    lastSndMsg = message;

    log("Payload: $bytes");
    log("Advertising...");

    await BlePeripheral.startAdvertising(
      services: [APP_UUID],
      localName: "aaa111",
      manufacturerData: manufacturerData,
      addManufacturerDataInScanResponse: true,
    );

    isAdvertising = true;
  }

  void log(String text) => print("[ble] ${text}");
}
