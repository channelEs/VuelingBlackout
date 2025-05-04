import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

import 'package:blacked_flut/ble.dart';
import 'package:blacked_flut/components/message.dart';
import 'package:flutter/material.dart';

class Protocol {
  static int flightNumber = 0;
  static final Ble _ble = Ble();

  static void Function(Message)? _onMessageCallback;

  static Map<String, void> receivedHashes = <String, void>{};

  static void setFlightNumber(int flightNumber) {
    Protocol.flightNumber = flightNumber;
  }

  static void initialize(int flightNumber) {
    Protocol.flightNumber = flightNumber;

    _ble.initialize((Message message) {
      String hash = generateMd5("${message.flightNumber}${message.content}");
      if (receivedHashes.containsKey(hash)) {
        return;
      }

      receivedHashes[hash] = ();

      if (flightNumber == message.flightNumber || message.flightNumber == 0) {
        debugPrint("Received message for me: ${message.content}");
        if (_onMessageCallback != null) {
          if (message.flightNumber == 0) {
            message.content = "(GLOBAL) ${message.content}";
          }
          _onMessageCallback!(message);
        }
      }

      // sendMessageRaw(message);
    });
  }

  static void setMessageCallback(void Function(Message) cb) {
    _onMessageCallback = cb;
  }

  static void sendMessage(String content) {
    if (content.length > 128) {
      return;
    }

    Message msg = Message(flightNumber, content);
    if (Ble.isInitialized) {
      _ble.sendMessage(msg);
    }
  }

  static void sendMessageRaw(Message msg) {
    _ble.sendMessage(msg);
  }

  static String generateMd5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }
}
