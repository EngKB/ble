import 'package:ble_test/ble_helpers/padlock_helper.dart';
import 'package:ble_test/unlock_device_bloc/unlock_device_event.dart';
import 'package:ble_test/unlock_device_bloc/unlock_device_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UnlockDeviceBloc extends Bloc<UnlockDeviceEvent, UnlockDeviceState> {
  UnlockDeviceBloc() : super(UnlockDeviceInitState()) {
    Device? device;
    on<UnlockDeviceRequest>(
      (event, emit) async {
        print(event.device.id + "token ${event.token}");
        device = event.device.connect(connectTimeout: 60000);
        device!.stateStream.listen((deviceState) async {
          print(deviceState.toString());
          // Fluttertoast.cancel();
          Fluttertoast.showToast(
              msg: deviceState.toString().split('.')[1],
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              fontSize: 16.0);
          if (deviceState == DeviceState.connected) {
            device!.writeData(
              '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'.toLowerCase(),
              '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'.toLowerCase(),
              true,
              PadLockHelper.encodeUnlockData(event.token),
            );
            bool notify = await device!.setNotify(
              '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'.toLowerCase(),
              '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'.toLowerCase(),
              true,
            );
            device!.deviceSignalResultStream.listen((e) {
              print('${event.device.id}  ${e.toString()}');
            });
            print("${event.device.id} notify: " + notify.toString());
          }
        });
      },
    );
    on<UnlockDeviceDispose>((event, emit) {
      device!.destroy();
    });
  }
}
