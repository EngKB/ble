import 'package:ble_test/unlock_reactive_device_bloc/unlock_device_bloc.dart';
import 'package:ble_test/unlock_reactive_device_bloc/unlock_device_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class UnlockReactivePage extends StatefulWidget {
  final DiscoveredDevice scanResult;

  const UnlockReactivePage({required this.scanResult, Key? key})
      : super(key: key);

  @override
  State<UnlockReactivePage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockReactivePage> {
  final TextEditingController token = TextEditingController(text: '00000000');
  final UnlockReactiveDeviceBloc unlockDeviceBloc = UnlockReactiveDeviceBloc();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    unlockDeviceBloc.add(UnlockReactiveDeviceDispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.scanResult.id),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                    labelText: "token",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)))),
                controller: token,
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  unlockDeviceBloc.add(UnlockReactiveDeviceRequest(
                      widget.scanResult.id, token.text));
                },
                child: const Text("unlock"))
          ],
        ),
      ),
    );
  }
}
