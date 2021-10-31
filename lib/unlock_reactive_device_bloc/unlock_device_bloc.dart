import 'package:ble_test/ble_helpers/padlock_ble_helper.dart';
import 'package:ble_test/unlock_device_bloc/unlock_device_state.dart';
import 'package:ble_test/unlock_reactive_device_bloc/unlock_device_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnlockReactiveDeviceBloc
    extends Bloc<UnlockReactiveDeviceEvent, UnlockDeviceState> {
  PadlockBLEHelper? padLockHelper;
  UnlockReactiveDeviceBloc() : super(UnlockDeviceInitState()) {
    on<UnlockReactiveDeviceRequest>(
      (event, emit) async {
        padLockHelper = PadlockBLEHelper();
        padLockHelper!.performAction(PadlockActions.UNLOCK, event.id,
            token: event.token, newToken: event.token);
        print(event.id + "token ${event.token}");
      },
    );
    on<UnlockReactiveDeviceDispose>((event, emit) {});
  }
}
