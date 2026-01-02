import 'package:flutter/material.dart';
import 'package:fqc_Prototype/Services/local_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'Models/fish_history.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await localStorage.init();

  await Hive.openBox<FishHistory>('fish_history');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
