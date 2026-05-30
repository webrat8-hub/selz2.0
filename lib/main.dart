import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SuperApp()));
}

class SuperApp extends StatefulWidget {
  const SuperApp({super.key});
  @override
  State<SuperApp> createState() => _SuperAppState();
}

class _SuperAppState extends State<SuperApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    _requestPerms();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://selz-final-1-5.vercel.app'));
  }

  Future<void> _requestPerms() async {
    await [Permission.contacts, Permission.storage, Permission.camera, Permission.phone].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: WebViewWidget(controller: controller)));
  }
}
