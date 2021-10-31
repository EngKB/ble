import 'package:flutter_blue_elves/flutter_blue_elves.dart';

abstract class UnlockDeviceEvent {}

class UnlockDeviceRequest extends UnlockDeviceEvent {
  final ScanResult device;
  final String token;
  UnlockDeviceRequest(this.device, this.token);
}

class UnlockDeviceDispose extends UnlockDeviceEvent {}
