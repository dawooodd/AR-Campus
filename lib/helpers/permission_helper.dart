import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestAppPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.camera,
    ].request();

    bool allGranted = true;
    bool anyPermanentlyDenied = false;

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
      if (status.isPermanentlyDenied) {
        anyPermanentlyDenied = true;
      }
    });

    if (anyPermanentlyDenied) {
      if (!context.mounted) return false;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Izin Diperlukan', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
                'Campus Hunto membutuhkan akses GPS dan Kamera agar fitur Peta dan AR dapat berfungsi.\n\nSilakan aktifkan secara manual di Pengaturan HP Anda.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings(); 
                },
                child: const Text('Buka Pengaturan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }

    return allGranted;
  }
}
