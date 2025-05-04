import 'dart:typed_data';

class Message {
  late int flightNumber;
  late String content;

  Message(this.flightNumber, this.content);
}

class BleMessage {
  late int messageId;
  late int messageIdx;
  late Uint8List payload;

  BleMessage(this.messageId, this.messageIdx, this.payload);
}
