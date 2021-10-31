import 'dart:async';

import 'package:ble_test/unlock_reactive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ReactiveScanPage extends StatefulWidget {
  const ReactiveScanPage({Key? key}) : super(key: key);

  @override
  State<ReactiveScanPage> createState() => _ReactiveScanPageState();
}

String serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'.toLowerCase();

class _ReactiveScanPageState extends State<ReactiveScanPage> {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> scanResult;
  List<DiscoveredDevice> loResult = [];
  @override
  void initState() {
    print("Reactive");
    FlutterBlueElves.instance.androidApplyBluetoothPermission((isOk) {
      print(isOk
          ? "The user agrees to turn on the Bluetooth permission"
          : "The user does not agrees to turn on the Bluetooth permission");
    });
    scanResult = flutterReactiveBle.scanForDevices(
      withServices: [Uuid.parse(serviceUuid)],
    ).listen((event) {
      print('reactive scan' + event.id);
      setState(() {
        loResult.add(event);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    scanResult.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reactive Scan"),
      ),
      body: ListView.builder(
        itemCount: loResult.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(
              loResult[i].id.toString(),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UnlockReactivePage(scanResult: loResult[i]),
                  ),
                );
              },
              child: Text("View"),
            ),
          );
        },
      ),
    );
  }
}
