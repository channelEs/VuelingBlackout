import 'package:flutter/services.dart';

class PeripheralService {
  static const MethodChannel _channel = MethodChannel('com.example.blePeripheral');

  // Function to start the peripheral (call to the native Android/iOS code)
  Future<void> startPeripheral() async {
    try {
      await _channel.invokeMethod('startPeripheral');
    } on PlatformException catch (e) {
      print("Failed to start peripheral: '${e.message}'.");
    }
  }
}
