import 'dart:async';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' as math;

import 'package:rxdart/rxdart.dart';
import 'package:convert/convert.dart';

enum BLEConnectionStatus {
  UNKNOWN,
  CONNECTED,
  DISCONNECTED,
  CONNECTING,
  DISCONNECTING,
  NOT_FOUND,
}

enum BLELockStatus {
  LOCKED,
  UNLOCKED,
  CLEAR,
}

class _Commands {
  static const UNLOCK_CMD = 0x00;
  static const CHANGE_TOKEN_CMD = 0x0B;
}

class _CommandLengths {
  static const UNLOCK_CMD = 0x05;
  static const CHANGE_TOKEN_CMD = 0x04;
}

class _ProtocolIndex {
  static const HEAD = 0;
  static const CMD = 1;
  static const LEN = 2;
  static const DATA = 3;
}

enum PadlockActions {
  UNLOCK,
  CHANGE_TOKEN,
}

enum PadlockMessageStatus {
  UNLOCK_FAILED,
  UNLOCK_SUCCESS,
  CLEAR,
}

class PadlockBLEHelper {
  final flutterReactiveBle = FlutterReactiveBle();

  bool isConnected = false;

  static const HEAD = 0x00;

  static final SERVICE_UUID =
      Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  final WRITE_CHAR_UUID = Uuid.parse('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
  final NOTIFY_CHAR_UUID = Uuid.parse('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

  late StreamSubscription<ConnectionStateUpdate> deviceStream;

  StreamController<BLEConnectionStatus> connectionStream = BehaviorSubject();
  StreamController<BLELockStatus> lockStatusStream = BehaviorSubject();
  StreamController<PadlockMessageStatus> messageStream = BehaviorSubject();

  PadlockActions? queuedAction;
  String? deviceID;

  // PadlockBLEHelper() {
  //   flutterReactiveBle.initialize();
  // }

  void dispose() {
    try {
      if (deviceID != null) flutterReactiveBle.clearGattCache(deviceID!);
      // flutterReactiveBle.deinitialize();
      deviceStream.cancel();
      connectionStream.close();
      lockStatusStream.close();
      messageStream.close();
    } catch (e) {
      print('cancel stream error $e');
    }
  }

  void performAction(
    PadlockActions action,
    String macAddress, {
    String? token,
    String? newToken,
  }) {
    print('normalized mac is $macAddress');

    if (!isConnected) {
      queuedAction = action;
      _connectToDevice(
        macAddress,
        token: token,
        newToken: newToken,
      );
      return;
    }
    switch (action) {
      case PadlockActions.UNLOCK:
        _unlockDevice(macAddress, token!);
        break;
      case PadlockActions.CHANGE_TOKEN:
        _changeToken(macAddress, token!, newToken!);
        break;
    }
  }

  void _connectToDevice(
    String macAddress, {
    String? token,
    String? newToken,
  }) async {
    deviceID = macAddress;
    deviceStream = flutterReactiveBle.connectToDevice(
      id: macAddress,
      servicesWithCharacteristicsToDiscover: {
        SERVICE_UUID: [
          WRITE_CHAR_UUID,
          NOTIFY_CHAR_UUID,
        ],
      },
    ).listen((event) async {
      print('status is $event');
      Fluttertoast.showToast(
          msg: event.connectionState.toString(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: mat.Colors.black,
          textColor: mat.Colors.white,
          fontSize: 16.0);
      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          isConnected = false;
          try {
            connectionStream.sink.add(BLEConnectionStatus.CONNECTING);
          } catch (e) {
            print('error in connection stream is $e');
          }
          break;
        case DeviceConnectionState.connected:
          try {
            connectionStream.sink.add(BLEConnectionStatus.CONNECTED);
          } catch (e) {
            print('error in connection stream is $e');
          }
          // final services =
          //     await flutterReactiveBle.discoverServices(macAddress);
          // services.forEach((service) {
          //   print('services are ${service.characteristicIds}');
          //   print('services are ${service.serviceId}');
          // });

          flutterReactiveBle
              .subscribeToCharacteristic(
            QualifiedCharacteristic(
                characteristicId: NOTIFY_CHAR_UUID,
                serviceId: SERVICE_UUID,
                deviceId: macAddress),
          )
              .listen((data) {
            _readInfoFromDevice(
              data,
              macAddress,
              token: token,
              newToken: newToken,
            );
          });
          isConnected = true;
          if (queuedAction != null) {
            performAction(queuedAction!, macAddress,
                token: token, newToken: newToken);
            queuedAction = null;
          }
          break;
        case DeviceConnectionState.disconnecting:
          isConnected = false;
          try {
            connectionStream.sink.add(BLEConnectionStatus.DISCONNECTING);
          } catch (e) {
            print('error in connection stream is $e');
          }
          break;
        case DeviceConnectionState.disconnected:
          isConnected = false;
          try {
            connectionStream.sink.add(BLEConnectionStatus.DISCONNECTED);
            switch (event.failure?.code ?? ConnectionError.failedToConnect) {
              case ConnectionError.unknown:
                connectionStream.add(BLEConnectionStatus.UNKNOWN);
                break;
              case ConnectionError.failedToConnect:
                connectionStream.add(BLEConnectionStatus.NOT_FOUND);
                break;
            }
          } catch (e) {
            print('error in connection stream is $e');
          }
          break;
      }
    });
  }

  _changeToken(String macAddress, String currentToken, String newToken) async {
    List<int> curr = [
      int.parse(currentToken.substring(0, 2), radix: 16),
      int.parse(currentToken.substring(2, 4), radix: 16),
      int.parse(currentToken.substring(4, 6), radix: 16),
      int.parse(currentToken.substring(6, 8), radix: 16),
    ];
    List<int> newT = [
      int.parse(newToken.substring(0, 2), radix: 16),
      int.parse(newToken.substring(2, 4), radix: 16),
      int.parse(newToken.substring(4, 6), radix: 16),
      int.parse(newToken.substring(6, 8), radix: 16),
    ];
    List<int> buffer = [
          HEAD,
          _Commands.CHANGE_TOKEN_CMD,
          _CommandLengths.CHANGE_TOKEN_CMD,
        ] +
        newT +
        curr;
    print('the buffer is $buffer');

    await flutterReactiveBle.writeCharacteristicWithoutResponse(
        QualifiedCharacteristic(
            characteristicId: WRITE_CHAR_UUID,
            serviceId: SERVICE_UUID,
            deviceId: macAddress),
        value: buffer);
  }

  _readInfoFromDevice(
    List values,
    String macAddress, {
    String? token,
    String? newToken,
  }) async {
    print('values are $values');
    if (values.length > 0) {
      print("value: ${values}");
      final head = values[0];
      print('head response is $head');
      final cmd = values[1];
      final dataLength = values[2];
      print('response command is $cmd');
      print('response data length is $dataLength');
      switch (cmd) {
        case _Commands.UNLOCK_CMD:
          final List<int> data = [];
          for (int i = _ProtocolIndex.DATA;
              i < _ProtocolIndex.DATA + dataLength;
              i++) {
            data.add(values[i]);
          }
          final unlockSuccess = data.last;
          print('unlock status is $unlockSuccess');
          if (unlockSuccess == 0) {
            messageStream.add(PadlockMessageStatus.UNLOCK_SUCCESS);
            lockStatusStream.add(BLELockStatus.UNLOCKED);
          } else {
            messageStream.add(PadlockMessageStatus.UNLOCK_FAILED);
          }
          final List<int> token = [];
          for (int i = _ProtocolIndex.DATA + dataLength as int;
              i < _ProtocolIndex.DATA + dataLength + 4;
              i++) {
            token.add(values[i]);
          }
          print('token is ${hex.encode(token)}');
          break;
        case _Commands.CHANGE_TOKEN_CMD:
          final List<int> data = [];
          for (int i = _ProtocolIndex.DATA;
              i < _ProtocolIndex.DATA + dataLength;
              i++) {
            data.add(values[i]);
          }
          final unlockSuccess = data.last;
          print('change token status is $unlockSuccess');
          if (unlockSuccess == 0) {
            messageStream.add(PadlockMessageStatus.UNLOCK_SUCCESS);
            lockStatusStream.add(BLELockStatus.UNLOCKED);
          } else {
            messageStream.add(PadlockMessageStatus.UNLOCK_FAILED);
          }
          final List<int> token = [];
          for (int i = _ProtocolIndex.DATA + dataLength as int;
              i < _ProtocolIndex.DATA + dataLength + 4;
              i++) {
            token.add(values[i]);
          }
          print('token is ${hex.encode(token)}');
          break;
      }
    }
  }

  _unlockDevice(String macAddress, String bleToken) async {
    List<int> token = [
      int.parse(bleToken.substring(0, 2), radix: 16),
      int.parse(bleToken.substring(2, 4), radix: 16),
      int.parse(bleToken.substring(4, 6), radix: 16),
      int.parse(bleToken.substring(6, 8), radix: 16),
    ];
    print('token is $token');
    // token = [0x70, 0xdf, 0x7a, 0x05];
    int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    List<int> buffer = [
          HEAD,
          _Commands.UNLOCK_CMD,
          _CommandLengths.UNLOCK_CMD,
        ] +
        Uint8List.fromList(
            [unixTime >> 24, unixTime >> 16, unixTime >> 8, unixTime]) +
        [0x01] +
        token;
    print('the bufer is $buffer');

    final key = Key(Uint8List.fromList([
      0x2b,
      0x7e,
      0x15,
      0x16,
      0x28,
      0xae,
      0xd2,
      0xa6,
      0xab,
      0xf7,
      0x15,
      0x88,
      0x09,
      0xcf,
      0x4f,
      0x3c
    ]));
    final encrypter = Encrypter(AES(
      key,
      mode: AESMode.ctr,
    ));
    final iv = IV.fromLength(16);
    final encryptedData = encrypter.encryptBytes(buffer, iv: iv).bytes;
    print('encrypted data is  $encryptedData');
    await flutterReactiveBle.writeCharacteristicWithoutResponse(
      QualifiedCharacteristic(
          characteristicId: WRITE_CHAR_UUID,
          serviceId: SERVICE_UUID,
          deviceId: macAddress),
      value: buffer,
    );
  }
}
