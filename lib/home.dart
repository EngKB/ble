import 'package:ble_test/ble_helpers/new_padlock_ble_helper.dart';
import 'package:ble_test/reactive_scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';

class MyHome extends StatefulWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  @override
  void initState() {
    NewPadlockBleHelper();
    FlutterBlueElves.instance.androidApplyLocationPermission((isOk) {
      print(isOk
          ? "User agrees to grant location permission"
          : "User does not agree to grant location permission");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => const ScanPage(),
            //       ),
            //     );
            //   },
            //   child: const Text("Scan"),
            // ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReactiveScanPage(),
                  ),
                );
              },
              child: const Text("Scan"),
            ),
          ],
        ),
      ),
    );
  }
}
