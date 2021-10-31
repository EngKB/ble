import 'dart:async';

import 'package:ble_test/unlock_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  FlutterBlueElves flutterBlueElves = FlutterBlueElves.instance;
  late StreamSubscription<ScanResult> scanResult;
  List<ScanResult> loResult = [];
  @override
  void dispose() {
    scanResult.cancel();
    super.dispose();
  }

  @override
  void initState() {
    print("Elevs");
    scanResult = FlutterBlueElves.instance.startScan(20000).listen((device) {
      print('scan ' + device.macAddress! + ' ' + device.uuids.toString());
      setState(() {
        loResult.add(device);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                print("Refresh");
                loResult.clear();
                scanResult.cancel();
                scanResult =
                    FlutterBlueElves.instance.startScan(20000).listen((device) {
                  print('scan ' +
                      device.macAddress! +
                      ' ' +
                      device.uuids.toString());
                  setState(() {
                    loResult.add(device);
                  });
                });
              });
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: ListView.builder(
          itemCount: loResult.length,
          itemBuilder: (context, i) {
            return ListTile(
                title: Text(loResult[i].id.toString()),
                subtitle: Row(
                  children: loResult[i].uuids.map((e) => Text(e)).toList(),
                ),
                trailing: loResult[i].uuids.contains(
                        '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'.toLowerCase())
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UnlockPage(scanResult: loResult[i]),
                            ),
                          );
                        },
                        child: const Text("view"),
                      )
                    : const SizedBox());
          }),
    );
  }
}
