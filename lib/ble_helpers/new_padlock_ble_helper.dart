import 'dart:async';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart' as mat;

class _Commands {
  static const unlock = 0x00;
  static const changeToken = 0x0B;
  static const powerPercentage = 0x0A;
  static const beamStatus = 0x09;
}

class _CommandLengths {
  static const unlock = 0x05;
  static const changeToken = 0x04;
  static const powerPercentage = 0x01;
  static const beamStatus = 0x01;
}

enum BLEConnectionStatus {
  unknown,
  connected,
  disconnected,
  connecting,
  disconnecting,
  failedToConnect,
}
const head = 0x00;
final _serviceUuid = Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
final _writeUuid = Uuid.parse('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
final _notifyUuid = Uuid.parse('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

class NewPadlockBleHelper {
  NewPadlockBleHelper();
  static late StreamSubscription<ConnectionStateUpdate> deviceStream;
  static final flutterReactiveBle = FlutterReactiveBle();
  late StreamController<BLEConnectionStatus> _connectionInfoResponse;

  void Function(BLEConnectionStatus) get addConnectionInfoResponse =>
      _connectionInfoResponse.sink.add;

  Stream<BLEConnectionStatus> get getConnectionInfoResponse =>
      _connectionInfoResponse.stream.asBroadcastStream();

  late StreamController<String> _infoResponse;

  void Function(String) get addInfoResponse => _infoResponse.sink.add;

  Stream<String> get getInfoResponse =>
      _infoResponse.stream.asBroadcastStream();

  connectToDevice(String macAddress) {
    print("connect to " + macAddress);
    _connectionInfoResponse = StreamController<BLEConnectionStatus>();
    deviceStream = flutterReactiveBle
        .connectToDevice(
            id: macAddress,
            servicesWithCharacteristicsToDiscover: {
              _serviceUuid: [
                _writeUuid,
                _notifyUuid,
              ],
            },
            connectionTimeout: const Duration(seconds: 30))
        .listen((event) async {
      Fluttertoast.showToast(
          msg: event.connectionState.toString(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: mat.Colors.black,
          textColor: mat.Colors.white,
          fontSize: 16.0);
      if (event.failure != null) {
        Fluttertoast.showToast(
            msg: event.failure!.code.toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: mat.Colors.black,
            textColor: mat.Colors.white,
            fontSize: 16.0);
        if (event.failure!.code == ConnectionError.failedToConnect) {
          addConnectionInfoResponse(BLEConnectionStatus.failedToConnect);
        } else {
          addConnectionInfoResponse(BLEConnectionStatus.failedToConnect);
        }
      }
      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          {
            try {
              addConnectionInfoResponse(BLEConnectionStatus.connecting);
            } catch (e) {
              print('error in connection stream is $e');
            }
            break;
          }
        case DeviceConnectionState.connected:
          {
            try {
              addConnectionInfoResponse(BLEConnectionStatus.connected);
            } catch (e) {
              print('error in connection stream is $e');
            }
            flutterReactiveBle
                .subscribeToCharacteristic(
              QualifiedCharacteristic(
                  characteristicId: _notifyUuid,
                  serviceId: _serviceUuid,
                  deviceId: macAddress),
            )
                .listen((event) {
              _readInfoFromDevice(event, macAddress);
            });
            break;
          }
        case DeviceConnectionState.disconnected:
          {
            addConnectionInfoResponse(BLEConnectionStatus.disconnected);
            break;
          }
        case DeviceConnectionState.disconnecting:
          {
            addConnectionInfoResponse(BLEConnectionStatus.disconnecting);
            break;
          }
      }
    });
  }

  unlockDevice(String token, String macAddress) async {
    print("unlock " + macAddress + " with " + token);
    int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    List<int> buffer = [
          head,
          _Commands.unlock,
          _CommandLengths.unlock,
        ] +
        Uint8List.fromList(
            [unixTime >> 24, unixTime >> 16, unixTime >> 8, unixTime]) +
        [0x01] +
        _parseToken(token);
    await flutterReactiveBle
        .writeCharacteristicWithoutResponse(
          QualifiedCharacteristic(
              characteristicId: _writeUuid,
              serviceId: _serviceUuid,
              deviceId: macAddress),
          value: _encryptData(buffer),
        )
        .then((value) => () {
              print('unlock Device acknowledgment');
            })
        .catchError((err) {
      print('unlock Device error ' + err);
    });
  }

  checkPowerPercentage(String token, String macAddress) async {
    print("check Power Percentage " + macAddress + " with " + token);
    List<int> buffer = [
          head,
          _Commands.powerPercentage,
          _CommandLengths.powerPercentage,
        ] +
        [0x00] +
        _parseToken(token);
    await flutterReactiveBle
        .writeCharacteristicWithoutResponse(
            QualifiedCharacteristic(
                characteristicId: _writeUuid,
                serviceId: _serviceUuid,
                deviceId: macAddress),
            value: _encryptData(buffer))
        .then((value) => () {
              print('check Power Percentage acknowledgment');
            })
        .catchError((err) {
      print('check Power Percentage error ' + err);
    });
  }

  changeToken(String token, String newToken, String macAddress) async {
    print("change token " + macAddress + " from " + token + " to " + newToken);
    List<int> buffer = [
          head,
          _Commands.changeToken,
          _CommandLengths.changeToken,
        ] +
        _parseToken(newToken) +
        _parseToken(token);

    await flutterReactiveBle
        .writeCharacteristicWithoutResponse(
            QualifiedCharacteristic(
                characteristicId: _writeUuid,
                serviceId: _serviceUuid,
                deviceId: macAddress),
            value: _encryptData(buffer))
        .then((value) => () {
              print('change token acknowledgment');
            })
        .catchError((err) {
      print('check Power Percentage acknowledgment error ' + err);
    });
  }

  checkBeamStatus(String token, String macAddress) async {
    print("check Beam status " + macAddress + " with " + token);
    List<int> buffer = [
          head,
          _Commands.beamStatus,
          _CommandLengths.beamStatus,
        ] +
        [0x00] +
        _parseToken(token);
    await flutterReactiveBle.writeCharacteristicWithoutResponse(
        QualifiedCharacteristic(
            characteristicId: _writeUuid,
            serviceId: _serviceUuid,
            deviceId: macAddress),
        value: _encryptData(buffer));
  }

  List<int> _parseToken(String token) {
    return [
      int.parse(token.substring(0, 2), radix: 16),
      int.parse(token.substring(2, 4), radix: 16),
      int.parse(token.substring(4, 6), radix: 16),
      int.parse(token.substring(6, 8), radix: 16),
    ];
  }

  List<int> _encryptData(List<int> buffer) {
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
    return encrypter.encryptBytes(buffer, iv: iv).bytes;
  }

  _readInfoFromDevice(List data, String macAddress) async {
    print('response length: ' + data.length.toString());
    final cmd = data[1];
    switch (cmd) {
      case _Commands.unlock:
        {
          print("unlock response: " + data.toString());
          break;
        }
      case _Commands.changeToken:
        {
          print("change Token response: " + data.toString());
          break;
        }
      case _Commands.powerPercentage:
        {
          print("power peercentage response: " + data.toString());
          break;
        }
      case _Commands.beamStatus:
        {
          print('lock beam status response: ' + data.toString());
          break;
        }
    }
  }
}
