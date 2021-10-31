import 'package:flutter_blue_elves/flutter_blue_elves.dart';

abstract class UnlockReactiveDeviceEvent {}

class UnlockReactiveDeviceRequest extends UnlockReactiveDeviceEvent {
  final String id;
  final String token;
  UnlockReactiveDeviceRequest(this.id, this.token);
}

class UnlockReactiveDeviceDispose extends UnlockReactiveDeviceEvent {}
