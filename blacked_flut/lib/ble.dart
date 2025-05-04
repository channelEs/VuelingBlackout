import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:blacked_flut/components/message.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:leb128/leb128.dart';
import 'package:permission_handler/permission_handler.dart';

class Ble {
  static const APP_UUID = "bf27730d-860a-4e09-889c-2d8b7a9e0fe7";
  static const APP_UUID2 = "00002A18-0000-1000-8000-00806F9B34FB";
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  static const headerLength = 2;
  static const packetSize = 20;

  static int currentMessageId = 0;

  late void Function(Message) _onMessageCallback;

  static bool isInitialized = false;
  static bool isAdvertising = false;
  static bool isLocked = false;
  static bool isScanning = false;

  late String myName;

  late final FlutterReactiveBle flutterReactiveBle;
  late final Queue<BleMessage> messagesQueue;

  late final Map<int, List<BleMessage>> partialMessages;

  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );

  Ble() {
    flutterReactiveBle = FlutterReactiveBle();
    messagesQueue = Queue();
    partialMessages = Map();
    myName = getRandomString(8);
  }

  void initialize(void Function(Message) onMsgCb) {
    if (isInitialized) {
      return;
    }

    _onMessageCallback = onMsgCb;
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

      Timer.periodic(Duration(milliseconds: 20), (timer) async {
        if (isLocked) {
          return;
        }

        if (messagesQueue.isNotEmpty) {
          if (isAdvertising) {
            await BlePeripheral.stopAdvertising();
            isAdvertising = false;
          }

          BleMessage message = messagesQueue.removeFirst();
          log(
            "Sending message ${message.messageId}, ${message.messageIdx}: ${message.payload}",
          );
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
        "Received ${device.manufacturerData.length - 2} bytes from ${device.id} (${device.name})",
      );

      Uint8List payload = device.manufacturerData.sublist(2);
      log("Payload: $payload");

      int messageId = payload[0];
      int messageIdx = payload[1];

      Uint8List messagePayload = payload.sublist(2);

      bool isLast = messageIdx & 1 <= 0;

      if (isLast) {
        if (partialMessages.containsKey(messageId)) {
          log("Recv last partial");
          List<BleMessage> partials = partialMessages[messageId]!;
          partials.add(BleMessage(messageId, messageIdx, messagePayload));

          partials.sort((a, b) {
            if (((a.messageIdx & 127) >> 1) > ((b.messageIdx & 127) >> 1)) {
              return 1;
            } else {
              return -1;
            }
          });

          int flightNumber = Leb128.decodeUnsigned(partials[0].payload);
          int lebBytes = (flightNumber.bitLength / 7).ceil();

          log("Flight number $flightNumber in $lebBytes bytes");

          BytesBuilder bb = new BytesBuilder();
          int lastIdx = -1;
          for (int i = 0; i < partials.length; i++) {
            if (partials[i].messageIdx > lastIdx) {
              bb.add(partials[i].payload);
              lastIdx = partials[i].messageIdx;
            }
          }

          Uint8List fullPayload = bb.toBytes();
          Uint8List contentBytes = fullPayload.sublist(lebBytes);
          log("Full received $contentBytes");
          String content = utf8.decode(contentBytes);

          log("Received $content from ${device.name} (${device.id})");

          Message rcvMsg = Message(flightNumber, content);
          _onMessageCallback(rcvMsg);
          return;
        }

        int flightNumber = Leb128.decodeUnsigned(messagePayload);
        int lebBytes = (flightNumber.bitLength / 7).ceil();
        Uint8List contentBytes = messagePayload.sublist(lebBytes);
        String content = utf8.decode(contentBytes);

        log("Received $content from ${device.name} (${device.id})");

        Message rcvMsg = Message(flightNumber, content);
        _onMessageCallback(rcvMsg);
      } else {
        if (!partialMessages.containsKey(messageId)) {
          partialMessages[messageId] = [
            BleMessage(messageId, messageIdx, messagePayload),
          ];
          log("Recv first partial");
        } else {
          partialMessages[messageId]!.add(
            BleMessage(messageId, messageIdx, messagePayload),
          );
          log("Recv partial");
        }
      }
    });
  }

  void doSend(BleMessage message) async {
    BytesBuilder bb = BytesBuilder();

    bb.addByte(message.messageId);
    bb.addByte(message.messageIdx);
    bb.add(message.payload);

    Uint8List bytes = bb.toBytes();

    var manufacturerData = ManufacturerData(manufacturerId: 0xFF, data: bytes);

    log("Sending payload: $bytes");

    isLocked = true;

    await BlePeripheral.startAdvertising(
      services: [APP_UUID],
      localName: myName,
      manufacturerData: manufacturerData,
      addManufacturerDataInScanResponse: true,
    );

    isAdvertising = true;
    isLocked = false;
  }

  void sendMessage(Message message) {
    Uint8List contentBytes = utf8.encode(message.content);
    Uint8List flightNumberBytes = Leb128.encodeUnsigned(message.flightNumber);

    bool needsFragmentation = false;
    if (contentBytes.length + flightNumberBytes.length >
        packetSize - headerLength) {
      needsFragmentation = true;
    }

    if (!needsFragmentation) {
      BytesBuilder bb = BytesBuilder();

      bb.add(flightNumberBytes);
      bb.add(contentBytes);

      Uint8List payload = bb.toBytes();

      BleMessage bleMessage = BleMessage(currentMessageId % 256, 0, payload);
      messagesQueue.add(bleMessage);
    }
  }

  void log(String text) => print("[ble] ${text}");
}
