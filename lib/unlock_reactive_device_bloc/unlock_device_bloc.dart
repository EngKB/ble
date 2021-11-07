import 'package:ble_test/ble_helpers/new_padlock_ble_helper.dart';
import 'package:ble_test/unlock_reactive_device_bloc/unlock_device_event.dart';
import 'package:ble_test/unlock_reactive_device_bloc/unlock_device_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnlockReactiveDeviceBloc
    extends Bloc<UnlockReactiveDeviceEvent, UnlockReactiveDeviceState> {
  NewPadlockBleHelper padLockHelper = NewPadlockBleHelper();
  UnlockReactiveDeviceBloc() : super(UnlockReactiveDeviceInitState()) {
    on<ConnectReactiveDeviceRequest>((event, emit) async {
      padLockHelper.connectToDevice(event.macAddress);
      padLockHelper.getConnectionInfoResponse.listen((e) async {
        print(event.macAddress + " " + e.toString());
        add(ConnectionStatusChanged(e));
      });
    });
    on<UnlockReactiveDeviceRequest>(
      (event, emit) async {
        padLockHelper.unlockDevice(event.id, event.token);
      },
    );
    on<ChangeTokenRequest>((event, emit) {
      padLockHelper.changeToken(event.id, event.token, event.newToken);
    });
    on<CheckPowerPercentage>((event, emit) {
      padLockHelper.checkPowerPercentage(event.id, event.token);
    });
    on<ConnectionStatusChanged>(
      (event, emit) {
        if (event.bleConnectionStatus == BLEConnectionStatus.disconnected) {
          emit(UnlockReactiveDeviceDisconnected());
        } else if (event.bleConnectionStatus == BLEConnectionStatus.connected) {
          emit(UnlockReactiveDeviceConnected());
        } else if (event.bleConnectionStatus ==
            BLEConnectionStatus.connecting) {
          emit(UnlockReactiveDeviceConnecting());
        }
      },
    );
  }
}
