import 'package:ble_test/ble_helpers/new_padlock_ble_helper.dart';

abstract class UnlockReactiveDeviceEvent {}

class ConnectReactiveDeviceRequest extends UnlockReactiveDeviceEvent {
  final String macAddress;
  ConnectReactiveDeviceRequest(this.macAddress);
}

class ConnectionStatusChanged extends UnlockReactiveDeviceEvent {
  final BLEConnectionStatus bleConnectionStatus;
  ConnectionStatusChanged(this.bleConnectionStatus);
}

class UnlockReactiveDeviceRequest extends UnlockReactiveDeviceEvent {
  final String id;
  final String token;
  UnlockReactiveDeviceRequest(this.id, this.token);
}

class UnlockReactiveDeviceDispose extends UnlockReactiveDeviceEvent {}

class ChangeTokenRequest extends UnlockReactiveDeviceEvent {
  final String id;
  final String token;
  final String newToken;
  ChangeTokenRequest(this.id, this.token, this.newToken);
}

class CheckPowerPercentage extends UnlockReactiveDeviceEvent {
  final String id;
  final String token;
  CheckPowerPercentage(this.id, this.token);
}
