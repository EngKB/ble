import 'package:ble_test/unlock_device_bloc/unlock_device_bloc.dart';
import 'package:ble_test/unlock_device_bloc/unlock_device_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';

class UnlockPage extends StatefulWidget {
  final ScanResult scanResult;

  const UnlockPage({required this.scanResult, Key? key}) : super(key: key);

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  final TextEditingController token = TextEditingController(text: '00000000');
  final UnlockDeviceBloc unlockDeviceBloc = UnlockDeviceBloc();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    unlockDeviceBloc.add(UnlockDeviceDispose());

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
                  unlockDeviceBloc
                      .add(UnlockDeviceRequest(widget.scanResult, token.text));
                },
                child: const Text("unlock"))
          ],
        ),
      ),
    );
  }
}
